# ----------------------------------------------------------------------------
#  Copyright 2005-2013 WSO2, Inc. http://www.wso2.org
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
# ----------------------------------------------------------------------------
#
# Class bps::params
#
# This class manages bps parameters
#
# Parameters:
#
# Usage: Uncomment the variable and assign a value to override the nodes.pp value
#
#

class bps::params {
#  $package_repo         = 'https://s3.amazonaws.com/cloudpreview/wso2_appcloud/packs'
#  $depsync_svn_repo     = 'https://svn.appfactory.domain.com/wso2/repo/'
#  $local_package_dir    = '/mnt/packs'
#
#  # Service subdomains
#  $domain               = 'wso2.com'
#  $as_subdomain         = 'bps'
#  $management_subdomain = 'management'
#
#  $admin_username       = 'admin'
#
#  # MySQL server configuration details
#  $mysql_server         = 'mysql.wso2.com'
#  $mysql_port           = '3306'
#  $max_connections      = '100000'
#  $max_active           = '150'
#  $max_wait             = '360000'
#
#  # Database details
#  $registry_user        = 'registry'
#  $registry_database    = 'governance'
#
#  $userstore_user       = 'userstore'
#  $userstore_database   = 'userstore'
#
#  # Depsync settings
#  $svn_user             = 'wso2'
#
#  #LDAP settings 
#  $ldap_connection_uri      = 'ldap://localhost:10389'
#  $bind_dn                  = 'uid=admin,ou=system'
#  $user_search_base         = 'ou=system'
#  $group_search_base        = 'ou=system'
#  $sharedgroup_search_base  = 'ou=SharedGroups,dc=wso2,dc=org'
}
