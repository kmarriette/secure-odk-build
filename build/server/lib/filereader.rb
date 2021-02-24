require 'json'
class FileReader
  def self.readPDF()
    file_path = File.expand_path(File.dirname(__FILE__))
    pdfFile="./../../public/sdf/pdf.json"
    absolute_path = File.join(file_path, pdfFile)
    file = File.read(absolute_path)
    pdf_data = JSON.parse(file)
    pdf_data.deep_symbolize_keys!
    pdf_data
 end

 def self.readSDF()
   file_path = File.expand_path(File.dirname(__FILE__))
   sdfFile="./../../public/sdf/sdf.json"
   absolute_path = File.join(file_path, sdfFile)
   file = File.read(absolute_path)
   pdf_data = JSON.parse(file)
   pdf_data.deep_symbolize_keys!
   pdf_data
end

def self.readProfileName(sdf_data)
  pdfFormDef=sdf_data[:form]
  ccName=!pdfFormDef[:ccprofile].blank? ? pdfFormDef[:ccprofile] : "cc1"
end

def self.contextSecurityMechanisms(sdfData, myCCName)

	secMechanisms=Hash.new
	isFound=0
	ccDef=Hash.new
	ccs =sdfData[:contextcategories]
		ccsLength=ccs.length
		if(ccsLength>0)
			(0..(ccsLength-1)).each do|i|
				ccDef=ccs[i]
				ccDef.deep_symbolize_keys!
				ccDefName=ccDef[:name]
				if(ccDefName==myCCName)
					isFound=1
					break
				end
			end
			#take public incase no level is found
			if(isFound==0)
				ccDef=ccs[0]
			end
		end
	ccDef
end


def self.staticClassify(data)
 	sdfData=data[:sdf]
 	pdfData=data[:pdf]
  pdfFormDef=pdfData[:form]
 	ccName=pdfFormDef[:ccprofile]
  if(ccName.blank?)
    ccName= "cc1"
  end
 	ccMechanisms=sdfData

 	dataControls=data[:controls]
 	sdf_attributes=pdfFormDef[:attributes]

 	(0..(dataControls.length-1)).each do|i|

 		formElement=dataControls[i]
 		puts "============================"
 		formElement.deep_symbolize_keys!

    formType=formElement[:type]
    if(formType=="group")
      children=formElement[:children]
      sChildren=[]
      xN=children.length-1
      (0..(xN)).each do |kk|
        childElement=children[kk]
        childElement.deep_symbolize_keys!
        myFormElement=classifyAttribute(sdf_attributes,childElement,ccMechanisms)
        sChildren << myFormElement
      end
      formElement[:children]=sChildren
    else
      formElement=classifyAttribute(sdf_attributes,formElement,ccMechanisms)
    end
 		dataControls[i]=formElement
 	end
 	data[:controls]=dataControls
 	data
 end

 def self.classifyAttribute(sdf_attributes,formElement,ccMechanisms)
   puts "form Element  Before"+formElement.to_s
   pdfFormElement=Hash.new
   level=""
   psfunction=Hash.new
   (0..(sdf_attributes.length-1)).each do|j|
     pdfFormElement=	sdf_attributes[j]
     pdfFormElement.deep_symbolize_keys!
     sdfName=pdfFormElement[:name]
     if(sdfName==formElement[:name])
       psfunction=pdfFormElement[:psparams]
       level=pdfFormElement[:level]
       break
     end
   end
   sens=Hash.new
   sens["name"]="sens"
   sens["type"]="uiSens"
   sens["id"]="sens"

   isNoLevel=(level.nil? or level.length==0 or level.blank? or level.empty?)
   #puts "pdfFormElement="+pdfFormElement.to_s
   if(psfunction.nil?)
     sens[:level]=level if(!isNoLevel)
   end

   puts "level not empty"+level if(!isNoLevel)
   #puts "SDF="+sdfData.to_s
   if(!isNoLevel)
     sens["securitymechanisms"]=pickLevelMechanism(ccMechanisms,level)
   else
     sens["securitymechanisms"]=Hash.new
   end

   formElement[:sens]=sens
   #puts "form Element  After"+formElement.to_s
   formElement

 end


 def self.pickLevelMechanism(cc,level)
 	myMech=Hash.new
 	cc.deep_symbolize_keys! if !cc.nil?
 	case level
 		when "critical"
 			myMech=cc[:critical]
 		when "confidential"
 			myMech=cc[:confidential]
 		else
 			myMech=cc[:public]
 	end
     myMech
 end

end
