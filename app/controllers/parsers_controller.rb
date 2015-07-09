# File: parsers_controller.rb
# Purpose of class: Populates the database with file named schedule.csv
# This software follows GPL license.
# TEM-DF Group
# FGA-UnB Faculdade de Engenharias do Gama - Universidade de Brasília
class ParsersController < ApplicationController

	# Reload the page index
	def index
		render "index"
		CUSTOM_LOGGER.info("Reload index")
	end

	# Upload schedule.csv file in the database
 	def upload
		exist_csv_medical_schedule_document = params[:document]
		
		# Checks for document and starts the parser
		if exist_csv_medical_schedule_document
			file_path = Rails.root.join('public', 'csv', 'schedules.csv')
			File.open(file_path , 'wb') {     
				|file| file.write(document.read)
			}
			Parser.save_data('public/csv/schedules.csv')
			redirect_to root_path
			CUSTOM_LOGGER.info("Held the parser")
		else
			redirect_to 'http://0.0.0.0:3000/parsers'
			CUSTOM_LOGGER.error("Failure to start the parser")
		end
	end
end
