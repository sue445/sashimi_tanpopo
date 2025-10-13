update_file "test3.txt" do |content|
  content.gsub!("name", params[:name])
  content.gsub!("lang", params[:lang])
end
