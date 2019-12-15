from __future__ import absolute_import, division, print_function
__metaclass__ = type

ANSIBLE_METADATA = {'metadata_version': '1.1',
                    'status': ['preview'],
                    'supported_by': 'community'}

DOCUMENTATION = r'''
---
module: sas_metadata
version_added: 2.8
short_description: create, modify and query SAS Metadata objects
description:
    - This module can be used to:
		- create new SAS metadata objects
		- modify existing objects' attributes, associations and permissions
		- delete an existing object
		- query the attributes of an existing object
	- Under the hood it runs SAS code to do all of the above, so it must be executed on a machine that has
	  SAS already installed
	- The C(object_type) parameter specifies the type of object to create, while the C(object_params)
	  specifies the attributes of the object
	- There are several types of objects selectable. If they are not sufficient, it is possible to use
	  the _generic_ type and specify the exact structure of the object required using a json-like syntax
	- The module is idempotent, it will not recreate existing objects if their structure already matches
	  what was requested. However, keep in mind that currently the module does not support removal of existing
	  attributes or associations
	- Since the module is idempotent, it is possible to use the create_object action C(action) to not only
	  create new objects, but also update existing ones with new attributes, new associations and new permissions
	- The module uses the type and name of the object to verify if it already exists, so make sure that your object
	  names are unique
options:
  action:
    description:
    - Specify the action you want to carry out in the SAS Metadata. Note that create_object can also
	  be used to update existing objects, since the module does not recreate already existing objects
    type: str
	choices: [ create_object, delete_object, get_object_info ]
	default: create_object
  object_type:
    description:
    - Specify the type of the object you want to delete, create or query. 
	- For C(action) = create_object, the type specified can be one of the following:
		- _generic_
		- base_library
		- directory
		- netezza_library
		- oracle_library
		- user
		- usergroup
	- Since the type for action "create_object" corresponds to the suffix of the SAS macro "metautil_create_" that is actually called to
	  create the object, it is possible to extende the functionality of the create_object action by adding a new metautil_create_
	  macro in the src/metautil folder and running the compile.py script
	- For C(action) = delete_object or get_object_info, the type specified should be the actual SAS Metadata type
	  of the object that should be queried or deleted (eg. ServerComponent, IdentityGroup etc.)
    type: str
  object_params:
    description:
    - Specify the details of how to carry out the action specified in C(action)
	- For C(action) = create_object and C(object_type) = _generic_, the following parameter must be provided:
		- object_structure: Json-like string explaining the structure of the object to create. 
		  See the documentation of src/metautil/metautil_create_object.sas for more information
	- For C(action) = create_object and C(object_type) != _generic_, the parameters to be provided should be the ones
	  expected by the corresponding metautil_create_ macro. For example, for C(object_type) = directory, the only parameter
	  is "dir_to_create_full_path", since that's the only parameter of the macro metautil_create_directory.
	  Note that parameters declared in SAS as "name=" are considered optional, so assigning a value to those is not mandatory
	- For C(action) = delete_object or get_object_info this parameter is not used
    type: dict
  object_selection_query:
	description:
	- For C(action) = create_object this parameter is not used
	- For C(action) = delete_object or get_object_info this parameter is the URI of the object to be selected or delete, 
	  see here for the possible format: https://documentation.sas.com/?docsetId=lrmeta&docsetTarget=n10jctx8iblta9n17b4fwr7tawii.htm&docsetVersion=9.4&locale=en
    type: str
  object_permissions:
	description:
	- Lists the permissions to be set on the object. This is a dictionary that can contain two key-value pairs:
	    - act: The act entry is a dictionary that can contain a single key-value pair, act_name. This is the name of the act to be applied to the
			   object		  
		- group: The group entry is a list of dictionaries. Each entry in the list must have the following values:
		  - group_name: User group the permission should be set for
		  - permission_name: Name of the permission to set (eg. ReadMetadata, WriteMember)
		  - authorization: Authorization level for the permission, [D, G, R] for Deny, Grant or Remove
	- For C(action) = delete_object or get_object_info this parameter is not used
    type: dict
  sas_executable:
	description:
	- Path of the SAS executable
    type: path
	default: /sas/SASHome/SASFoundation/9.4/sas
  metadata_connection_program:
	description:
	- Path of the SAS program that specifies the options to connect to the Metadata Server. This and metadata_connection_options are mutually_exclusive
    type: path
	default: /sas/config/Lev1/SASMeta/MetadataServer/metaparms.sas
  metadata_connection_options:
	description:
	- Dictionary holding the the options to connect to the Metadata Server. This and metadata_connection_options are mutually_exclusive.
	- The dictionary should contain the following values:
		- host: Host of the Metadata Server
		- port: Port of the Metadata Server
		- user: user to connect to the Metadata Server
		- password: password to connect to the Metadata Server
    type: dict
 
notes:
- The M(sas_metadata) currently does not support removing of existing attributes or associations.
author:
- Andrea Defronzo (ING)
'''

EXAMPLES = r'''
 - name: Creates a user named Foo
   sas_metadata:
	object_type: user
	object_params:
		user_name: Foo
		
 - name: Creates a user group named MyGroup and deny permissions on it to SASAdministrators group
   sas_metadata:
	object_type: usergroup
	object_params:
		user_name: MyGroup
	object_permissions:
		group:
		  - group_name : "GSFAX9-CMT_DTSASAdministratorsDAExperts"
		    permission_name : "ReadMetadata"
		    authorization : "D"

- name: Create a Netezza Library assigned on the SASApp and SASAnotherApp Application Servers
  sas_metadata:
    object_type: netezza_library
    object_params:
		library_name: My Netezza Library
		library_libref: mylib
		library_metadata_path: /Shared Data
		server_name: MyNetezzaServer
		user_group_name: NetezzaGroup
		netezza_host: netezza.host
		netezza_user: NETEZZA_USER
		netezza_password: NETEZZA_PWD
		netezza_db: DM_CMP
		netezza_schema: MY_SCHEMA
		connection_name: Connection to Netezza
		library_appservers:
		- SASApp
		- SASAnotherApp
		
- name: Update the FileNavigation property of the "Foo - Workspace Server" ServerComponent
  sas_metadata:
    object_type: _generic_
    object_params:
        object_structure: |
                    "{_type: ServerComponent, 
                     _name: Foo - Workspace Server,
                     Properties: [{_type: Property, 
                                   _name: File Navigation - Foo, 
                                   SQLType: 12, 
                                   PropertyName: FileNavigation, 
                                   DefaultValue: /tmp
                                  ]
                     }"
'''

RETURN = r'''
object_attrs:
    description: Attributes of the metadata object created, deleted or queried
    returned: success
    type: dict
    sample: {"Id" : "A51D1CFC.B0000024", "UsageVersion" : "1000000"}
'''

from ansible.module_utils.basic import AnsibleModule
import subprocess
import os
import re
import zipfile
import json
import base64
import datetime

def writeline(f, line):
	f.write(line)
	f.write('\n')

def create_macro_call_string(macro_full_path, object_params):
	macro_name = os.path.splitext(os.path.basename(macro_full_path))[0]

	with open(macro_full_path, 'r') as macro:                
		macro_content = macro.read().replace('\n', ' ').replace('\r\n', ' ')
		
		p = re.compile('%macro {0}\((.+?)\)'.format(macro_name), re.IGNORECASE)		
		m = p.match(macro_content)

		if not bool(m):
			raise ValueError('Macro ' + macro_full_path + ' does not have a valid %macro declaration')
			
		macro_args_str = m.group(1)

	macro_args = macro_args_str.split(',')
	macro_call = ['%', macro_name]

	i = 0
	for arg in macro_args:
		arg = arg.strip()

		optional = False
		if '=' in arg:
			value = arg.split('=')[1]
			arg = arg.split('=')[0]
			optional = True

		if optional:
			value = object_params[arg] if object_params.has_key(arg) else value
		else:
			if not object_params.has_key(arg):
				raise ValueError('A value must be supplied for Object Parameter ' + arg + ' required by macro ' + macro_name)
			else:
				value = object_params[arg]

		if type(value) == list:
			value = '#'.join(value)

		macro_call.append('(' if i == 0 else ',')
		macro_call.append(arg + '=' + value)

		i += 1

	macro_call.append(')')

	return ''.join(macro_call)

def create_sas_pgm_for_action_create(sas_pgm, source_code_folder, object_type, object_params, object_permissions):
	if object_type == '_generic_':
		macro_name = 'metautil_create_object.sas'
		macro_to_invoke = os.path.join(source_code_folder, 'metautil', macro_name)
		
		if not os.path.exists(macro_to_invoke):
			raise ValueError('SAS macro metautil_create_object does not exist')
			
		if dict_value_is_empty(object_params, 'object_structure'):
			raise ValueError('Object Parameter object_structure cannot be empty for object type _generic_')
			
		macro_invocation_string = '%metautil_create_object({0})'.format(object_params['object_structure'])
	else:
		macro_name = 'metautil_create_' + object_type.lower() + '.sas'
		macro_to_invoke = os.path.join(source_code_folder, 'metautil', macro_name)
	
		if not os.path.exists(macro_to_invoke):
			raise ValueError('A SAS macro to create objects of type ' + object_type + ' does not exist')
			
		macro_invocation_string = create_macro_call_string(macro_to_invoke, object_params)
		
	writeline(sas_pgm, macro_invocation_string)
	writeline(sas_pgm, '%if &SYSCC. > 4 %then %return;')
	writeline(sas_pgm, '%let changed = &_METAUTIL_LAST_OBJECT_WAS_CHANGD.;')
	
	if object_permissions != None:
		group_permission = object_permissions.get('group', [])
		act_permission = object_permissions.get('act')
		
		if len(group_permission) == 0 and act_permission == None:
			raise ValueError('For object_permissions at least one of "group" or "act" arrays of permissions must be defined')
			
		if act_permission != None:
			act_name = act_permission['act_name']
			
			writeline(sas_pgm, 
						'%metautil_set_act(&_METAUTIL_LAST_OBJECT_URI., {0})'.format(act_name))
			writeline(sas_pgm, '%if &SYSCC. > 4 %then %return;')
			writeline(sas_pgm, '%let changed = %eval(&changed. + &_METAUTIL_LAST_OBJECT_WAS_CHANGD.);')
			
		for perm in group_permission:
			group_name = perm['group_name']
			permission_name = perm['permission_name']
			authorization = perm['authorization']
			
			writeline(sas_pgm, 
						'%metautil_set_group_permissions(&_METAUTIL_LAST_OBJECT_URI., {0}, {1}, {2})'.format(group_name, permission_name, authorization))
			writeline(sas_pgm, '%if &SYSCC. > 4 %then %return;')
			writeline(sas_pgm, '%let changed = %eval(&changed. + &_METAUTIL_LAST_OBJECT_WAS_CHANGD.);')
	
	writeline(sas_pgm, '%metautil_write_result_x_ansible(&_METAUTIL_LAST_OBJECT_URI., &changed., &RESULT_FILE.)')
	writeline(sas_pgm, '%if &SYSCC. > 4 %then %return;')
	
def create_sas_pgm_for_action_delete(sas_pgm, source_code_folder, object_type, object_selection_query):
	raise ValueError('Action "delete" is not implemented yet')

def create_sas_pgm_for_action_query(sas_pgm, source_code_folder, object_type, object_selection_query):
	raise ValueError('Action "delete" is not implemented yet')

def create_sas_program(action, source_code_folder, object_type, object_params, object_permissions, object_selection_query, metadata_connection_program, metadata_connection_info):
	timestamp = datetime.datetime.now().strftime('%Y_%m_%d_%H_%M_%S')
	sas_program = os.path.join(source_code_folder, 'pgm_' + timestamp + '.sas')
	
	if metadata_connection_info != None:
		server = metadata_connection_info['host']
		port = metadata_connection_info['port']
		user = metadata_connection_info['user']
		password = metadata_connection_info['password']
		metadata_connection_options = 'options metaserver="{0}" metaport={1} metauser="{2}" metapass="{3}";'.format(server, port, user, password)
	else:
		metadata_connection_options = '%include "{0}";'.format(metadata_connection_program)
	
	with open(sas_program, 'w') as sas_pgm:
		writeline(sas_pgm, '%macro execute;')
		
		writeline(sas_pgm, '%let RESULT_FILE = %sysget(RESULT_FILE);')
	
		writeline(sas_pgm, 'options insert=(sasautos "{0}");'.format(os.path.join(source_code_folder, 'util')))
		writeline(sas_pgm, 'options insert=(sasautos "{0}");'.format(os.path.join(source_code_folder, 'fsutil')))
		writeline(sas_pgm, '%util_add_subdirs_to_sasautos({0}, INSERT)'.format(source_code_folder))
		
		writeline(sas_pgm, 'options set=METAUTIL_JAVAPATH "{0}";'.format(os.path.join(source_code_folder, 'metautil')))
		
		writeline(sas_pgm, metadata_connection_options)
		writeline(sas_pgm, '%if &SYSCC. > 4 %then %return;')

		action = action.lower()
		if action == 'create_object' :
			create_sas_pgm_for_action_create(sas_pgm, source_code_folder, object_type, object_params, object_permissions)
		elif action == 'delete_object' :
			create_sas_pgm_for_action_delete(sas_pgm, source_code_folder, object_type, object_selection_query)
		elif action == 'get_object_info' :
			create_sas_pgm_for_action_query(sas_pgm, source_code_folder, object_type, object_selection_query)
		else:
			raise ValueError('Invalid action: ' + action)
			
		writeline(sas_pgm, '%mend execute;')
		writeline(sas_pgm, '%execute;')		
	
	return sas_program

def execute_sas_program(program_to_execute, sas_executable_path, source_code_folder):
	timestamp = datetime.datetime.now().strftime('%Y_%m_%d_%H_%M_%S')
	result_file = os.path.join(source_code_folder, 'result_' + timestamp)
	log_file = os.path.join(source_code_folder, 'log_' + timestamp + '.log')
	
	proc = subprocess.Popen([sas_executable_path, '-sysin', program_to_execute, '-log' , log_file, '-set', 'RESULT_FILE', result_file], 
								stdout=subprocess.PIPE,
								stderr=subprocess.PIPE)
								
	stdout, stderr = proc.communicate()

	sas_error = ''
	if os.path.exists(log_file):
		sas_error = check_sas_log_for_errors(log_file)
	
	if proc.returncode != 0:
		if sas_error != '':
			raise RuntimeError('SAS command returned non-zero value, error in SAS log: {0}'.format(sas_error))
		else:
			raise RuntimeError('SAS command returned non-zero value, stdout={0}, stderr={1}'.format(stdout, stderr))
	elif sas_error != '':	
		raise RuntimeError('Execution of the SAS program failed with the following error: ' + sas_error)
		
	return result_file

def parse_sas_exec_result(result_file):
	if not os.path.exists(result_file):
		raise RuntimeError('SAS output file was not created, check the SAS log')
	
	changed = False
	object = None
	with open(result_file, 'r') as results:
		i = 0
		json_data = ''
		for line in results:
			if i == 0:
				if int(line) == 0:
					changed = False
				else:
					changed = True
			else:
				json_data = json_data + ' ' + line
		
			i += 1

		object = json.loads(json_data)
		
	return (object, changed)				
		
def unzip_sas_code_package(sas_code_package_content, dest_folder):
	zipped_package = os.path.join(dest_folder, 'sascode_package.zip')
	with open(zipped_package, 'wb') as zip:
		zip.write(base64.b64decode(sas_code_package_content))
		
	z = zipfile.ZipFile(zipped_package)
	z.extractall(path=dest_folder)
	
def check_sas_log_for_errors(sas_log):
	with open(sas_log, 'r') as reader:
		for line in reader.readlines():
			if re.match('^ERROR.*:.*', line):
				return line
			
	return ''
	
def dict_value_is_empty(dict, key):
	if not dict.has_key(key):
		return True
	elif dict[key] == None or dict[key] == '':
		return True
		
	return False

def main():
	module = AnsibleModule(
		argument_spec = dict(
			action=dict(default='create_object', choices=['create_object', 'delete_object', 'get_object_info'],type='str'),
			metadata_connection_info=dict(type='dict'),
			metadata_connection_program=dict(default='/sas/config/Lev1/SASMeta/MetadataServer/metaparms.sas',type='path'),
			sas_executable=dict(default='/sas/SASHome/SASFoundation/9.4/sas',type='path'),
			object_type=dict(required='True',type='str'),
			object_params=dict(type='dict'),
			object_permissions=dict(type='dict'),
			object_selection_query=dict(type='str')
		),
		mutually_exclusive=[
							[ 'metadata_connection_info', 'metadata_connection_program' ],
							[ 'object_params', 'object_selection_query' ],
							[ 'object_permissions', 'object_selection_query' ]
						   ],
		required_if=[
					 [ 'action', 'create_object', [ 'object_params' ] ],
					 [ 'action', 'delete_object', [ 'object_selection_query' ] ],
					 [ 'action', 'get_object_info', [ 'object_selection_query' ] ]
					]
    )
	
	action = module.params['action']
	metadata_connection_info = module.params['metadata_connection_info']
	metadata_connection_program = module.params['metadata_connection_program']
	sas_executable = module.params['sas_executable']
	object_type = module.params['object_type']
	object_params = module.params['object_params']
	object_permissions = module.params['object_permissions']
	object_selection_query = module.params['object_selection_query']
	
	if not os.path.exists(sas_executable):
		module.fail_json(msg='SAS executable ' + sas_executable + ' does not exist')
	elif metadata_connection_info == None and not os.path.exists(metadata_connection_program):
		module.fail_json(msg='Metadata connection program ' + metadata_connection_program + ' does not exist')
	elif metadata_connection_info != None :
		if dict_value_is_empty(metadata_connection_info, 'host'):
			module.fail_json(msg='host cannot be empty in metadata_connection_info')
		elif dict_value_is_empty(metadata_connection_info, 'port'):
			module.fail_json(msg='port cannot be empty in metadata_connection_info')
		elif dict_value_is_empty(metadata_connection_info, 'user'):
			module.fail_json(msg='user cannot be empty in metadata_connection_info')
		elif dict_value_is_empty(metadata_connection_info, 'password'):
			module.fail_json(msg='password cannot be empty in metadata_connection_info')

	SAS_CODE_PACKAGE = ''	
	
	try:
		source_code_folder = os.path.join(module.tmpdir, 'sas_code')
		os.mkdir(source_code_folder)
		unzip_sas_code_package(SAS_CODE_PACKAGE, source_code_folder)

		sas_pgm_to_execute = create_sas_program(action, source_code_folder, object_type, object_params, object_permissions, 
													object_selection_query, metadata_connection_program, metadata_connection_info)
		
		execution_output = execute_sas_program(sas_pgm_to_execute, sas_executable, source_code_folder)
		
		object, changed = parse_sas_exec_result(execution_output)

	except Exception as e:
		module.fail_json(msg="Error during execution: " + str(e))
	
	module.exit_json(object_attrs=object, changed=changed)	
	
if __name__ == '__main__':
	main()