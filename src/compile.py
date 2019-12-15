#!/bin/python

import os
import zipfile
import base64
import re

def zip_dir(dir_to_zip, output_zip):
	dest_zip = zipfile.ZipFile(output_zip, 'w', zipfile.ZIP_DEFLATED)
	
	for entry in os.listdir(dir_to_zip):
		element = os.path.join(dir_to_zip, entry)
		
		if os.path.isdir(element) == True:
			for root, dirs, files in os.walk(element):
				for file in files:
					dest_zip.write(os.path.join(root, file), arcname=os.path.relpath(os.path.join(root, file), os.path.join(dir_to_zip)))
			
	dest_zip.close()
	
def main():
	current_folder = os.path.dirname(os.path.abspath(__file__))
	
	dest_zip = os.path.join(current_folder, 'sascode.zip')
	
	source_python = os.path.join(current_folder, 'main.py')
	dest_python = os.path.join(os.path.dirname(current_folder), 'sas_metadata.py')

	zip_dir(current_folder, dest_zip)
	with open(dest_zip, 'r') as zip:
		encoded_zip = base64.b64encode(zip.read())
		
	with open(source_python, 'r') as src, open(dest_python, 'w') as dst:
		content = src.read()
		content = re.sub('SAS_CODE_PACKAGE = \'\'', 'SAS_CODE_PACKAGE = \'{0}\''.format(encoded_zip), content)
		dst.write(content)		
			
if __name__ == '__main__':
	main()