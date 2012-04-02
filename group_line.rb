#!/usr/bin/wallaby console

class Array
  def cdr
    car,*cdr = self
    cdr
  end

  def rcdr
    self[0..-2]
  end
end


class SlotRecord
  attr_reader :unavailable, :available, :used, :cpus, :memory, :groups

  def initialize(data)
    rec = data.split
    raise "Data format error: '#{data.chomp}'" unless rec.length == 6
    @unavailable, @available, @used = rec[0..2].map {|x| "1" == x}
    @cpus, @memory = rec[3..4].map {|x| x.to_i}
    # rec[5] is group[.subgroup]*.user@domain, keep only group[.subgroup]*
    @groups = rec[5].split("@")[0].split(".").rcdr
  end

  def update_group(group)
    if @used
      group.cpus += @cpus
      group.memory += @memory
    end
  end
end


class SubmitterRecord
  attr_reader :idle, :groups

  def initialize(data)
    rec = data.split
    raise "Data format error: '#{data.chomp}'" unless rec.length == 2
    @idle = rec[0].to_i
    # rec[1] is group[.subgroup]*.user@domain, keep only group[.subgroup]*
    @groups = rec[1].split("@")[0].split(".").rcdr
  end

  def update_group(group)
    group.idle += @idle
  end
end


class Group
  attr_reader :children
  attr_accessor :cpus, :memory, :quota, :idle

  def initialize
    @cpus = @memory = @quota = @idle = 0
    @children = Hash.new {|hash, key| hash[key] = Group.new}
  end

  def add_record(record, groups=record.groups)
    record.update_group(self)
    unless groups.empty?
      @children[groups[0]].add_record(record, groups.cdr)
    end
  end
end


unavail = avail = 0.0
groups = Group.new


feature = ::Wallaby::store.getFeature("AccountingGroups")
# GROUP_NAMES separator is whitepsace or comma. The name format is group[.subgroup]*.
feature.params["GROUP_NAMES"].split.map {|n| n.split(",")}.flatten.each do |group_name|
  names = group_name.split(".")
  group = groups
  names.each_with_index do |name, i|
    group = group.children[name]
    fullname = names[0..i].join(".")
    param = "GROUP_QUOTA_DYNAMIC_#{fullname}"
    puts "Unset config param: #{param} " unless feature.params.key?(param)
    group.quota = feature.params[param].to_f * 100
  end
end


# NOTE: If using an UNUSABLE filter, it is possible to have
#       Unavailable+Used slots. A filter such as Cpus==0 will not have
#       this problem. The result of Unvail+Used is that the Avail %
#       for slots can be >100%. Either the >100% needs to be allowed
#       or the Avail % could be adjusted to filter out
#       Unavailable+Used.
UNUSABLE = ARGV.length > 0 ? ARGV[0] : "FALSE"
UNUSED = 'State == "Unclaimed"'
USED = 'State != "Owner" && State != "Unclaimed"'
UNAVAILABLE = "State == \"Owner\" || (#{UNUSED} && #{UNUSABLE})"
AVAILABLE = "(#{UNAVAILABLE}) == FALSE"
SLOT_CMD = %{condor_status -format '%d' '#{UNAVAILABLE}' -format ' %d' '#{AVAILABLE}' -format ' %d' '#{USED}' -format ' %d' Cpus -format ' %d' Memory -format ' %s\n' 'ifThenElse(AccountingGroup=!=UNDEFINED, AccountingGroup, "None")'}
IO.popen(SLOT_CMD) do |sub|
  sub.each do |line|
    record = SlotRecord.new(line)
    unavail += record.cpus if record.unavailable
    avail += record.cpus if record.available
    groups.add_record(record)
  end
end


SUBMITTER_CMD = %{condor_status -submit -format "%d" IdleJobs -format " %s\n" Name}
IO.popen(SUBMITTER_CMD) do |sub|
  sub.each do |line|
    groups.add_record(SubmitterRecord.new(line))
  end
end


puts "Group          Used    Avail   Config     Diff    Idle"
groups.children.each do |name, group|
  printf "%-13s %5d  %6.2f%%  %6.1f%%  %7.2f %7d %s\n",
          name,
          group.cpus,
          (group.cpus/avail)*100,
          group.quota,
          (group.cpus/avail)*100 - group.quota,
          group.idle,
          group.quota == 0 ? "*" : ""
  group.children.each do |name, child|
    printf " `-%-10s %5d  %6.2f%%  %6.1f%%  %7.2f %7d %s\n",
           name,
           child.cpus,
           group.cpus == 0 ? 0.0 : (child.cpus/group.cpus.to_f)*100,
           child.quota,
           ((group.cpus == 0 ? 0.0 : (child.cpus/group.cpus.to_f)*100) - child.quota),
           child.idle,
           child.quota == 0 ? "*" : ""
  end
end
printf "        Total %5d  %6.2f%%                   %7d\n", groups.cpus, (groups.cpus/avail)*100, groups.idle
puts "* = no quota defined, freeloader"
