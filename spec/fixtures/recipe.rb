update_file "test.txt" do |content|
  content.gsub!("name", params[:name])
end

update_file "not_found.txt" do |content|
  raise "should not be called here!"
end
