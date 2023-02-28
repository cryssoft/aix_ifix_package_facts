#
#  FACT(S):     aix_ifix_package
#
#  PURPOSE:     This custom fact returns a hash of elements based on the list
#		of AIX installp packages that various ifixes need to know about
#		to decide whether they apply (and/or which spin to apply) on
#		each box.
#
#		This list will change over time for sure.  As such, there's no
#		good to come from pushing it to the Puppet Forge.  It will go
#		on Github and be documented there.
#
#  RETURNS:     (hash)
#
#  AUTHOR:      Chris Petersen, Crystallized Software
#
#  DATE:        February 27, 2023
#
#  NOTES:       Myriad names and acronyms are trademarked or copyrighted by IBM
#               including but not limited to IBM, PowerHA, AIX, RSCT (Reliable,
#               Scalable Cluster Technology), and CAA (Cluster-Aware AIX).  All
#               rights to such names and acronyms belong with their owner.
#
#		The usage is basically:
#
#		if ('kernel version' == $::facts['kernelrelease'] {
#
#		  if ('package name' in $::facts['aix_ifix_package'] {
#
#	  	    if ('version' == $::facts['aix_ifix_package']['package name']) {
#		    }
#		    else {
#		    }
#
#		  }
#		  else {
#		  }
#
#		}
#		else {
#		}
#
#		This more or less goes with aix_ifix_facts ($::facts['aix_ifix'])
#		to tell particular ifixes whether or not to install and maybe 
#		which version/spin of a particular patch to apply.  Many ifixes 
#		are based on just the $::facts['kernelrelease'], but some are 
#		based on the presence of optional packages like bos.cluster.rte 
#		or specific versions of a package w/in one 'kernelrelease'.
#
#-------------------------------------------------------------------------------
#
#  LAST MOD:    (never)
#
#  MODIFICATION HISTORY:
#
#	(none)
#
#-------------------------------------------------------------------------------
#
Facter.add(:aix_ifix_package) do
    #  This only applies to the AIX operating system
    confine :osfamily => 'AIX'

    #  Capture the installation status and version if it's there
    setcode do

        #  Start with a list of packages we know our current ifixes care about
        l_packages = [
                      'bind.rte',	 		# IJ44425
                      'bos.adt.include',		# IJ42159
                      'bos.cluster.rte',		# IJ41975, IJ44115
                      'bos.mp64', 			# IJ43869
                      'bos.net.tcp.bind', 		# IJ44425
                      'bos.net.tcp.bind_utils',		# IJ44425
                      'bos.net.tcp.client', 		# IJ41974, IJ43598
                      'bos.net.tcp.client_core', 	# IJ41974, IJ43598
                      'bos.net.tcp.server', 		# IJ44425
                      'bos.pfcdd.rte',			# IJ43877
                      'bos.perf.perfstat',		# IJ43876, IJ44114
                      'bos.printers.rte',		# IJ42162, IJ44559
                      'bos.rte.control',		# IJ42339, IJ45056
                      'printers.rte',			# IJ42162, IJ44559
                      'X11.base.lib',			# IJ42677, IJ43218
                     ]

        #  Define the hash we'll fill and return
        l_aixIFIXpackage = {}

        #  Loop over the list of packages we need to know about
        l_packages.each do |l_package|

            #  See if that shows up in the "lslpp -lc" output
            l_lines = Facter::Util::Resolution.exec('/bin/lslpp -lc ' + l_package + ' 2>/dev/null')

            #  Loop over the lines that were returned
            l_lines && l_lines.split("\n").each do |l_oneLine|
                #  Skip comments and blanks
                l_oneLine = l_oneLine.strip()
                next if l_oneLine =~ /^#/ or l_oneLine =~ /^$/

                #  Split on colons since that seems to work and give clean data
                l_list = l_oneLine.split(':')
                begin
                    l_aixIFIXpackage[l_list[1]] = l_list[2]
                end
            end

        end

        #  Implicitly return the contents of the hash
        l_aixIFIXpackage
    end
end
