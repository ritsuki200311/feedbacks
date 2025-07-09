module ApplicationHelper
  def sidebar_link_class(path)
    base_class = "px-4 py-2 rounded"
    if current_page?(path)
      "bg-blue-500 text-white #{base_class}"
    else
      "text-gray-700 hover:bg-gray-100 #{base_class}"
    end
  end
end