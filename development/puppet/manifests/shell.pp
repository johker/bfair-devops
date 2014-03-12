

define shexecution (
  $file, 
  $content,
  $user,
  $group  
) {
  
  
	  # Set Maven home on login 
	file { '${file}':
	    mode => 777,
	    owner => $username, 
	    group => $group,
	    content => $content
	} 
	  
	exec { "executesh":
	    command => "/bin/bash ${file}",
	    user => $username, 
	    logoutput => true,
	    require =>  File["${file}"] 
	}  
  
}