echo 'ERZ047015W/0310' $(date +"%d/%m/%y %T.%N") 'CICSFPR1 33489324/0001      : CICS has detected a storage inconsistency in transaction 'CPMI' executing as a background task.  The inconsistency is in storage area 30152628 at address 30152677' >> /var/cics_regions/CICSFPR1/console.000001
echo 'SERVICE_MESSAGE' $(date +"%d/%m/%y %T.%N") 'CICSFPR1 33489324/000     : TermAddr: 30152678, 88' >> /var/cics_regions/CICSFPR1/console.000001
echo 'SERVICE_MESSAGE' $(date +"%d/%m/%y %T.%N") 'CICSFPR1 33489324/000     : Dumping (ptr=0x30152614, size=200)' >> /var/cics_regions/CICSFPR1/console.000001
echo '0x30152614: 20 20 20 20 20 20 20 20 20 20 20 20 00 00 00 00    	             ....' >> /var/cics_regions/CICSFPR1/console.000001
echo '0x30152624: 00 00 00 58 20 20 20 20 20 20 20 20 20 20 20 20    	 ...X            ' >> /var/cics_regions/CICSFPR1/console.000001
echo '0x30152634: 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20    	                 ' >> /var/cics_regions/CICSFPR1/console.000001
echo '0x30152644: 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20    	                 ' >> /var/cics_regions/CICSFPR1/console.000001
echo '0x30152654: 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20    	                 ' >> /var/cics_regions/CICSFPR1/console.000001
echo '0x30152664: 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20    	                 ' >> /var/cics_regions/CICSFPR1/console.000001
echo '0x30152674: 20 20 20 20 30 30 31 32 31 30 30 20 20 20 9d 80    	     0012100   ..' >> /var/cics_regions/CICSFPR1/console.000001
echo '0x30152684: 20 1f a2 c0 20 20 20 20 20 20 20 20 20 20 20 20    	  .��            ' >> /var/cics_regions/CICSFPR1/console.000001
echo '0x30152694: 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20    	                 ' >> /var/cics_regions/CICSFPR1/console.000001
echo '0x301526a4: 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20    	                 ' >> /var/cics_regions/CICSFPR1/console.000001
echo '0x301526b4: 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20    	                 ' >> /var/cics_regions/CICSFPR1/console.000001
echo '0x301526c4: 20 20 20 20 20 20 20 20 20 20 20 20 30 39 39 39    	             0999' >> /var/cics_regions/CICSFPR1/console.000001
echo '0x301526d4: 39 2d 31 32 2d 33 31 2d                            	 9-12-31-    0999' >> /var/cics_regions/CICSFPR1/console.000001
echo 'SERVICE_MESSAGE' $(date +"%d/%m/%y %T.%N") 'CICSFPR1 33489324/000     : Dump complete for 30152614,200' >> /var/cics_regions/CICSFPR1/console.000001
echo 'SERVICE_MESSAGE' $(date +"%d/%m/%y %T.%N") 'CICSFPR1 33489324/000     : PDB: 3430dbe8, 36' >> /var/cics_regions/CICSFPR1/console.000001
echo 'SERVICE_MESSAGE' $(date +"%d/%m/%y %T.%N") 'CICSFPR1 33489324/000     : Dumping (ptr=0x3430d960, size=36)' >> /var/cics_regions/CICSFPR1/console.000001
echo '0x3430d960: 20 00 00 19 34 30 d9 48 00 00 00 00 00 00 00 00    	  ...40�H........' >> /var/cics_regions/CICSFPR1/console.000001
echo '0x3430d970: 33 3c 6e 5c 00 00 00 00 20 00 00 1d 34 30 d9 60    	 3<n\.... ...40�`' >> /var/cics_regions/CICSFPR1/console.000001
echo '0x3430d980: 00 00 00 00                                        	 ........ ...40�`' >> /var/cics_regions/CICSFPR1/console.000001
echo 'SERVICE_MESSAGE' $(date +"%d/%m/%y %T.%N") 'CICSFPR1 33489324/000     : Dump complete for 3430d960,36' >> /var/cics_regions/CICSFPR1/console.000001
echo 'ERZ030022E/2604' $(date +"%d/%m/%y %T.%N") 'CICSFPR1 33751354/0001      : Unable to allocate storage for incoming data' >> /var/cics_regions/CICSFPR1/console.000001
echo 'ERZ014016E/0036' $(date +"%d/%m/%y %T.%N") 'CICSFPR1 33751354/0001      : Transaction 'CPMI', Abend 'A27D', at '????'.' >> /var/cics_regions/CICSFPR1/console.000001

echo 'ERZ047015W/0310' $(date +"%d/%m/%y %T.%N") 'CICSFBAT 33489324/0001      : CICS has detected a storage inconsistency in transaction 'CPMI' executing as a background task.  The inconsistency is in storage area 30152628 at address 30152677' >> /var/cics_regions/CICSFBAT/console.000001
echo 'SERVICE_MESSAGE' $(date +"%d/%m/%y %T.%N") 'CICSFBAT 33489324/000     : TermAddr: 30152678, 88' >> /var/cics_regions/CICSFBAT/console.000001
echo 'SERVICE_MESSAGE' $(date +"%d/%m/%y %T.%N") 'CICSFBAT 33489324/000     : Dumping (ptr=0x30152614, size=200)' >> /var/cics_regions/CICSFBAT/console.000001
echo '0x30152614: 20 20 20 20 20 20 20 20 20 20 20 20 00 00 00 00    	             ....' >> /var/cics_regions/CICSFBAT/console.000001
echo '0x30152624: 00 00 00 58 20 20 20 20 20 20 20 20 20 20 20 20    	 ...X            ' >> /var/cics_regions/CICSFBAT/console.000001
echo '0x30152634: 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20    	                 ' >> /var/cics_regions/CICSFBAT/console.000001
echo '0x30152644: 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20    	                 ' >> /var/cics_regions/CICSFBAT/console.000001
echo '0x30152654: 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20    	                 ' >> /var/cics_regions/CICSFBAT/console.000001
echo '0x30152664: 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20    	                 ' >> /var/cics_regions/CICSFBAT/console.000001
echo '0x30152674: 20 20 20 20 30 30 31 32 31 30 30 20 20 20 9d 80    	     0012100   ..' >> /var/cics_regions/CICSFBAT/console.000001
echo '0x30152684: 20 1f a2 c0 20 20 20 20 20 20 20 20 20 20 20 20    	  .��            ' >> /var/cics_regions/CICSFBAT/console.000001
echo '0x30152694: 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20    	                 ' >> /var/cics_regions/CICSFBAT/console.000001
echo '0x301526a4: 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20    	                 ' >> /var/cics_regions/CICSFBAT/console.000001
echo '0x301526b4: 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20    	                 ' >> /var/cics_regions/CICSFBAT/console.000001
echo '0x301526c4: 20 20 20 20 20 20 20 20 20 20 20 20 30 39 39 39    	             0999' >> /var/cics_regions/CICSFBAT/console.000001
echo '0x301526d4: 39 2d 31 32 2d 33 31 2d                            	 9-12-31-    0999' >> /var/cics_regions/CICSFBAT/console.000001
echo 'SERVICE_MESSAGE' $(date +"%d/%m/%y %T.%N") 'CICSFBAT 33489324/000     : Dump complete for 30152614,200' >> /var/cics_regions/CICSFBAT/console.000001
echo 'SERVICE_MESSAGE' $(date +"%d/%m/%y %T.%N") 'CICSFBAT 33489324/000     : PDB: 3430dbe8, 36' >> /var/cics_regions/CICSFBAT/console.000001
echo 'SERVICE_MESSAGE' $(date +"%d/%m/%y %T.%N") 'CICSFBAT 33489324/000     : Dumping (ptr=0x3430d960, size=36)' >> /var/cics_regions/CICSFBAT/console.000001
echo '0x3430d960: 20 00 00 19 34 30 d9 48 00 00 00 00 00 00 00 00    	  ...40�H........' >> /var/cics_regions/CICSFBAT/console.000001
echo '0x3430d970: 33 3c 6e 5c 00 00 00 00 20 00 00 1d 34 30 d9 60    	 3<n\.... ...40�`' >> /var/cics_regions/CICSFBAT/console.000001
echo '0x3430d980: 00 00 00 00                                        	 ........ ...40�`' >> /var/cics_regions/CICSFBAT/console.000001
echo 'SERVICE_MESSAGE' $(date +"%d/%m/%y %T.%N") 'CICSFBAT 33489324/000     : Dump complete for 3430d960,36' >> /var/cics_regions/CICSFBAT/console.000001
echo 'ERZ030022E/2604' $(date +"%d/%m/%y %T.%N") 'CICSFBAT 33751354/0001      : Unable to allocate storage for incoming data' >> /var/cics_regions/CICSFBAT/console.000001
echo 'ERZ014016E/0036' $(date +"%d/%m/%y %T.%N") 'CICSFBAT 33751354/0001      : Transaction 'CPMI', Abend 'A27D', at '????'.' >> /var/cics_regions/CICSFBAT/console.000001
