
$special_file_filter = [
	"^Default.*\\.png.*",
	"^load\\d{0,2}\\.png.*",
	"^AppGuide.*\.png.*",
	"^Icon.*\\.png.*",
	"^egopv_.*\\.png.*"
]

class Censor

	attr_accessor :image_list
	attr_accessor :matched_image_list

	def initialize
		super
		@image_refer_reg_expression = /@"(.*?\.(?:png|jpg))"/
		@image_file_reg_expression = /(?:png|jpg)/

		@image_list = {}
		@matched_image_list = []
	end

	def file_filter(file_dir)
		Dir.foreach(file_dir) do |file|
			if file =~ /^\..*/
				next
			end

			file_full_path = file_dir + '/' + file
			if File.directory? file_full_path
				file_filter file_full_path
			else 
				if File.extname(file_full_path) == '.m'
					parse_objc_file file_full_path
				elsif File.extname(file_full_path) =~ /\.png/
					@image_list[File.basename(file_full_path)] = file_full_path
				end
					
			end
		end
	end

	def parse_objc_file(file_path)
		IO.readlines(file_path).each do |line|
			line.scan(@image_refer_reg_expression).each do |matched_content|
				matched_content.each do |single_matched_content|
					matched_image_list.push File.basename(single_matched_content)
				end
			end
		end
	end

	def get_unuseful_image_file(dir)
		file_filter(dir)
		@matched_image_list.each do |image_name|
			base_image_name =  File.basename image_name
			retain_image_name = File.basename(image_name).insert(File.basename(image_name).length - 4,"@2x")

			@image_list.delete base_image_name
			@image_list.delete retain_image_name
		end
		return kickout_special_file
	end

	def kickout_special_file 
		special_file_filter = []
		$special_file_filter.each do |single_filter|
			puts single_filter
			special_file_filter.push Regexp.new(single_filter)
		end

		special_file_filter.each do |reg|
			@image_list.each_key do |key|
				if reg.match(key)
					@image_list.delete key
				end
			end
		end

		return @image_list
	end
end

file = File.open(File.dirname(__FILE__) +'/' + 'rm_cmd','w')

censor = Censor.new
censor.get_unuseful_image_file(ARGV[0]).each_value do |unuseful_image|
	file.write("git rm #{unuseful_image}; \n")
end

file.close



