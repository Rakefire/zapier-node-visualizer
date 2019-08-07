require "json"
require "pry"
require "active_support/core_ext/object/blank"

file = File.read("zapfile.json")
zap_hash = JSON.parse(file)
zaps = zap_hash.dig("zaps")

puts ["Zap Count: #{zaps.length}", nil]

class Node
  def initialize(node, type:)
    @node = node
    @type = type
  end

  def to_s
    ["-", "(#{type})", api_style, api_formatter].join(" ")
  end

  private

  def api_style
    node["selected_api"]
  end

  def api_formatter
    return unless klass = Node.const_get(api_style)

    klass.new(node, type: type).to_s
  rescue NameError => e
  end

  attr_reader :node, :type

  class StreakDevAPI
    def initialize(node, type:)
      @node = node
      @type = type
    end

    def to_s
      step_title = @node.dig("meta", "stepTitle")
      assigned_to = @node.dig("params", "assignedTo")&.first
      assigned_to = "Assigned to #{assigned_to}" if assigned_to.present?
      due_date = @node.dig("params", "dueDate").to_s.split("}}").last
      due_date = " Due #{due_date}" if due_date.present?

      output = [step_title, assigned_to.to_s + due_date.to_s].map(&:presence).compact.map(&:strip).join(" - ")
      "(#{output})" if output.present?
    end
  end
end

class NodeList
  def initialize(nodes)
    @raw_nodes = nodes.map(&:last)
  end

  def nodes
    @nodes_data ||= begin
      trigger, actions = @raw_nodes.partition.with_index { |_, index| index.zero? }

      trigger
        .map { |n| Node.new(n, type: :trigger) } +
      actions
        .map { |n| Node.new(n, type: :action) }
    end
  end
end

zaps.each do |zap|
  title = zap.dig("title").strip
  puts title
  nodes = zap["nodes"]

  node_list =
    NodeList.new(nodes)
      .nodes
      .each { |n| puts n.to_s }

  puts
end
