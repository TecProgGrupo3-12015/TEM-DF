require "work_unit"

# File: medic.rb
# Purpose of class: This class is a model and contains attributes,            # associations and business methods for Medic entity.
# This software follows GPL license.
# TEM-DF Group
# FGA-UnB Faculdade de Engenharias do Gama - Universidade de Brasília
class Medic < ActiveRecord::Base
	belongs_to :work_unit
	has_many :schedules
	has_many :rating, through: :user
	has_many :comments

	# REVIEW: Is necessary this methos to be here? Probabily would be better fit #	on controller action.
	def self.search(speciality, work_unit)
		info_the_specialty = "Informe a Especialidade"
		if work_unit != "Informe a Região"
			@work_unit_instance = WorkUnit.find_by_name(work_unit)
			if(@work_unit_instance)
				if speciality != info_the_specialty
					specialty_and_id_work_unit = "speciality =  ? AND work_unit_id = ?"
					where(specialty_and_id_work_unit , speciality , @work_unit_instance.id).all
				else
					where("work_unit_id = ?", @work_unit_instance.id).all
				end
			end
		elsif speciality != info_the_specialty
			where("speciality =  ?", speciality).all
		else
		    nil
		end
	end
end
