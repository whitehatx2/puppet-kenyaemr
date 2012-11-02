class kenyaemr{package { "mysql-server": ensure => installed }  # Chaining the Notifications to control the order of the installation steps.    Notify["OpenMRS-1"] ->      Database_user['openmrs@localhost'] ->    Database_grant['openmrs@localhost'] ->  Notify["OpenMRS-2"] ->     Database['openmrs'] ->  Notify["OpenMRS-3"] ->    Exec['openmrs-module-kenyaemr-git-clone'] ->  Notify["OpenMRS-4"] ->    Exec["maven-install"] ->  Notify["OpenMRS-5"] ->    Exec["wget-concept-dictionary"] ->    Exec["apply-concept-dictionary"] ->	  Notify["OpenMRS-6"] ->    Exec["remove-previous-kenyaemr-distros"] ->    File ["/usr/share/tomcat6/.OpenMRS/modules"] ->  Notify["OpenMRS-7"] ->	File ["/usr/share/tomcat6/.OpenMRS/openmrs-runtime.properties"]notify {"OpenMRS-1":    message=> "Step 1. Create mysql user openmrs@localhost with temp password \'temp_openmrs\'.",  }  database_user{ 'openmrs@localhost':    ensure        => present,    password_hash => mysql_password('temp_openmrs'),  }  database_grant{'openmrs@localhost':    privileges => [all],  }notify {"OpenMRS-2":    message=> "Step 2. Create database openmrs",  }  database{ 'openmrs':    ensure => present,    charset => 'utf8',  } notify {"OpenMRS-3":    message=> "Step 3. Clone, fetch, merge a copy of openmrs-module-kenyaemr.git to /usr/src/openmrs-module-kenyaemr",  }  exec{ 'openmrs-module-kenyaemr-git-clone':    command => '/usr/bin/git clone --depth 1 git://github.com/I-TECH/openmrs-module-kenyaemr.git /usr/src/openmrs-module-kenyaemr',    creates => '/usr/src/openmrs-module-kenyaemr',    logoutput => 'true',  }    notify {"OpenMRS-4":    message=> "Step 4. Run maven install to create distro.zip",  }  exec{ "maven-install":    cwd => '/usr/src/openmrs-module-kenyaemr',    command => '/usr/bin/mvn install -DbuildDistro=true -DsetupDatabase=true',     logoutput => 'on_failure',    timeout => -1, 	  }  notify {"OpenMRS-5":    message=> "Step 5. wget concept dictionary.",  }  exec { "wget-concept-dictionary":    cwd => '/usr/src',    command => '/usr/bin/wget \'https://openmrs:openmrs@download.cirg.washington.edu/openmrs/dictionary/openmrs_concepts_1.9.0_20120727.sql\'',    creates => '/usr/src/openmrs_concepts_1.9.0_20120727.sql';  }  exec { "apply-concept-dictionary":    cwd => '/usr/src',    command => '/usr/bin/mysql openmrs < openmrs_concepts_1.9.0_20120727.sql',  }  notify {"OpenMRS-6":    message=> "Step 6. Remove old distro then copy  new distro into tomcat6 modules directory (usr/share/tomcat6/.OpenMRS/modules)",  }  exec{ "remove-previous-kenyaemr-distros":    cwd => '/usr/share/tomcat6/.OpenMRS/modules',    command => '/bin/rm -rf kenyaemr-distro-*',  }  file { '/usr/share/tomcat6/.OpenMRS/modules' :		ensure => directory,		group => 'tomcat6',		mode => '0775',		source => "/usr/src/openmrs-module-kenyaemr/distro/target/distro" ,		recurse => true  }  notify {"OpenMRS-7":    message=> "Step 7. Create openmrs-runtime.properties file in the .OpenMRS directory",  }  file {"/usr/share/tomcat6/.OpenMRS/openmrs-runtime.properties":    content => 'encryption.vector=kznZRqg+DbuOVWjhEl63cA==connection.url=jdbc:mysql://localhost:3306/openmrs?autoReconnect=true&sessionVariables=storage_engine=InnoDB&useUnicode=true&characterEncoding=UTF-8module.allow_web_admin=trueconnection.username=openmrsauto_update_database=falseencryption.key=UA0+SGpR1BG7538EsklrZQ==connection.password=temp_openmrs',  }  }