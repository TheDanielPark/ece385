#!/usr/bin/env python
# $Header: //acds/rel/18.1std/ip/sopc/app/alt-create-top-sim-script/alt-create-top-sim-files/alt_create_top_sim_script.py#1 $
#############################################################################
##  alt_create_top_sim_script.py
##
##  Altera Authentication Signing Utility
##
##  ALTERA LEGAL NOTICE
##
##  This script is  pursuant to the following license agreement
##  (BY VIEWING AND USING THIS SCRIPT, YOU AGREE TO THE
##  FOLLOWING): Copyright (c) 2013-2014 Altera Corporation, San Jose,
##  California, USA.  Permission is hereby granted, free of
##  charge, to any person obtaining a copy of this software and
##  associated documentation files (the "Software"), to deal in
##  the Software without restriction, including without limitation
##  the rights to use, copy, modify, merge, publish, distribute,
##  sublicense, and/or sell copies of the Software, and to permit
##  persons to whom the Software is furnished to do so, subject to
##  the following conditions:
##
##  The above copyright notice and this permission notice shall be
##  included in all copies or substantial portions of the Software.
##
##  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
##  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
##  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
##  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
##  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
##  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
##  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
##  OTHER DEALINGS IN THE SOFTWARE.
##
##  This agreement shall be governed in all respects by the laws of
##  the State of California and by the laws of the United States of
##  America.
##
##
##  CONTACTING ALTERA
##
##  You can contact Altera through one of the following ways:
##
##  Mail:
##     Altera Corporation
##     Applications Department
##     101 Innovation Drive
##     San Jose, CA 95134
##
##  Altera Website:
##     www.altera.com
##
##  Online Support:
##     www.altera.com/mysupport
##
##  Troubleshooters Website:
##     www.altera.com/support/kdb/troubleshooter
##
##  Technical Support Hotline:
##     (800) 800-EPLD or (800) 800-3753
##        7:00 a.m. to 5:00 p.m. Pacific Time, M-F
##     (408) 544-7000
##        7:00 a.m. to 5:00 p.m. Pacific Time, M-F
##
##     From other locations, call (408) 544-7000 or your local
##     Altera distributor.
##
##  The mySupport web site allows you to submit technical service
##  requests and to monitor the status of all of your requests
##  online, regardless of whether they were submitted via the
##  mySupport web site or the Technical Support Hotline. In order to
##  use the mySupport web site, you must first register for an
##  Altera.com account on the mySupport web site.
##
##  The Troubleshooters web site provides interactive tools to
##  troubleshoot and solve common technical problems.


import sys
import platform
import getopt
import platform
import os
import os.path
import string
import re
import subprocess

def usage():
	print("Usage: alt-create-top-sim-script --spd=<qsys-spd> --mem-init-spd=<mem_init_spd> ",\
	" --output-directory=<output_directory>")

	print()
	print("Create a top level modelsim simulation script called load_sim_file which sources qsys generated modelsim script\n",\
                  "and copies generated Memory Initialization Hex file to current sim directory. This is for internal use only")
	print()
	print("-h,--help            - prints usage")
	print("--spd                - path of qsys generated .spd file")
	print("--mem-init-spd       - path to the memory initialization .spd file")
	print("--output-directory   - output directory where the script will be created")

def main():
	#optionparsing
	try:
		opts,args=getopt.getopt(
		sys.argv[1:],"h",["help","spd=","mem-init-spd=","output-directory=","legacy-family="])
	except(etopt.GetoptError,err):
		print(str(err))
		usage()
		sys.exit(2)

	spd,mem_init_spd,output_directory= None,None,None
	legacy_family_list=["arriaiigx","arriaiigz","arriav","arriavgz","cycloneive","cycloneivgx","cyclonev", "cyclone10lp", "max10","maxii","maxv","stratixiv","stratixv","None"]
	#option handling
	for o, a in opts:
		if o in ("-h","--help"):
			usage()
			sys.exit()
		elif o == "--spd":
			spd=a
		elif o == "--mem-init-spd":
			mem_init_spd = a
		elif o == "--output-directory":
			output_directory = a
		else:
			print("Unhandled option: ", a)
			usage()
			sys.exit()

	for option in [spd]:
		if option == None:
			print("Missing argument --spd")
			usage()
			sys.exit()


	if (not output_directory):
		output_directory="./"

	hex_files_array = None
	spd_device_family = None
	legacy_family = 0

	#Check if legacy device family
	if (os.path.exists(spd)):
		spd_file=open(spd,"r")
		for line in spd_file:
			dev_family_match = re.match(" <deviceFamily name=\"(.*?)\"",line) ;
			if (dev_family_match):
				spd_device_family=dev_family_match.group(1)
		if (spd_device_family in legacy_family_list):
			legacy_family = 1
	else:
		print("Unable to find: "+ spd +".Please generate qsys testbench before proceeding further")


	if (mem_init_spd):
		if (os.path.exists(mem_init_spd)):
			mem_init_spd_file = open(mem_init_spd, "r")
		else:
			mem_init_spd_file = None


	if (legacy_family == 1 ):
		QSYS_SIMDIR=output_directory
		QSYS_MSIM_SCRIPT="msim_setup.tcl"
		subprocess.call(["ip-make-simscript","--spd="+spd, "--output-directory="+output_directory])
	else:
		QSYS_SIMDIR=os.path.dirname(spd)+"/sim"
		QSYS_MSIM_SCRIPT=QSYS_SIMDIR + "/mentor/msim_setup.tcl"

	#create load_sim.tcl script
	if (not os.path.exists(output_directory+"/mentor")):
		os.makedirs(output_directory+"/mentor")
	load_sim = output_directory +"/mentor/load_sim.tcl"
	load_sim_file=open (load_sim,"w");
	load_sim_file.write("# ------------------------------------------------------------------------------\n")
	load_sim_file.write("# Top Level Simulation Script to source msim_setup.tcl\n")
	load_sim_file.write("# ------------------------------------------------------------------------------\n")
	load_sim_file.write("set QSYS_SIMDIR "+ QSYS_SIMDIR +"\n")
	load_sim_file.write("source "+ QSYS_MSIM_SCRIPT +"\n")
	load_sim_file.write("# Copy generated memory initialization hex and dat file(s) to current directory\n")
	#copy generated hex and dat files
	if (mem_init_spd):
		if (os.path.exists(mem_init_spd)):
			for line in mem_init_spd_file:
				hex_match = re.match("<file path=\"(.*?)\" type=\"HEX\"",line) ;
				dat_match = re.match("<file path=\"(.*?)\" type=\"DAT\"",line) ;
				if (hex_match):
					load_sim_file.write("file copy -force " + os.path.dirname(mem_init_spd) + "/" + hex_match.group(1) + " ./ \n")
					print (hex_match.group(1))
				if (dat_match):
					load_sim_file.write("file copy -force " + os.path.dirname(mem_init_spd) + "/" + dat_match.group(1) + " ./ \n")
					print (dat_match.group(1))

if __name__=='__main__':
        main()
