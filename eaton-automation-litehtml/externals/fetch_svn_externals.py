import argparse
import os
import shutil
import sys
import subprocess
import time
import filecmp
import shutil

parser = argparse.ArgumentParser(description='Fetch SVN externals',)
parser.add_argument(
    '--svn_external_file', type=str, required=True, default=None,
    help='The text file containing the svn external definitions. The folder of the file will be used as the checkout directory.'
)
parser.add_argument(
    '--use_svn_export', type=bool, required=False, default=False,
    help='if set to true, an SVN export will be performed (by default a SVN checkout)'
)
parser.add_argument(
    '--svnuser', type=str, required=False, default="",
    help='SVN user (empty = default user set up on the PC)'
)
parser.add_argument(
    '--svnpwd', type=str, required=False, default="",
    help='SVN password (empty = default user pwd set up on the PC)'
)
parser.add_argument(
    '--trustservercertfailures', type=bool, required=False, default=False,
    help='if set to true, passes unknown-ca to the appropriate SVN option'
)
parser.add_argument(
    '--usecachecompare', type=bool, required=False, default=False,
    help='uses a temporary cache to store and compare whether there are changes in the SVN external definition'
)

args = parser.parse_args()
svnExternalFile = args.svn_external_file
useSvnExport = args.use_svn_export
svnUser = args.svnuser
svnPwd = args.svnpwd
trustservercertfailures = args.trustservercertfailures
useCacheCompare = args.usecachecompare

# Opening file

file = open(svnExternalFile, 'r')

# Important: Windows still has the restriction of 260 chars for RELATIVE paths
#            Therefore build the absolute path. If Long Paths is enabled in the
#            OS, it will work.
abs_path_external_file = os.path.abspath(svnExternalFile)
external_path = os.path.dirname(abs_path_external_file)

svn_server_url="https://chsscm001"

def remove_directory(path):
    if os.path.exists(path):
        shutil.rmtree(path)
    else:
        print(f"Directory {path} does not exist, skipping removal.")

def svn_checkout(url, revision, path):
    global useSvnExport, svnUser, svnPwd

    isSvnUpdate = False

    # caution: concat the string (or use format does NOT work properly)
    # use join to handle LF and other special characters correctly
    if os.path.exists(path):
        isSvnUpdate = True
        cmd = "svn update --non-interactive"
    else:
        if useSvnExport:
            cmd = " ".join(['svn', 'export', url, '-r', revision, path, '--non-interactive'])
        else:
            cmd = " ".join(['svn', 'checkout', url, '-r', revision, path, '--non-interactive'])

        if svnUser:
            cmd = cmd + " " + " ".join(['--username', svnUser, '--password', svnPwd])

    if trustservercertfailures:
        cmd = cmd + " --trust-server-cert-failures='unknown-ca'"

    retryCounter = 0
    returnCode = -1
    while returnCode != 0 and retryCounter < 3: 
        print(cmd + "\n", flush=True)

        p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        p.communicate()
        returnCode = p.returncode
        print(f"Return code is: {returnCode}\n", flush=True)
        
        if (returnCode != 0):
            retryCounter = retryCounter + 1
            print("Retry (after 5 seconds) ...", flush=True)
            time.sleep(5)
            if not (isSvnUpdate):
                print(f"Removing complete directory {path} first ...", flush=True)
                remove_directory(path)

    return returnCode

def svn_update(revision, path):
    global svnUser, svnPwd
    
    cmd = " ".join(['svn', 'update', path, '-r', revision])
    
    if svnUser:
        cmd = cmd + " " + " ".join(['--username', svnUser, '--password', svnPwd])
        
    if trustservercertfailures:
        cmd = cmd + " --trust-server-cert-failures='unknown-ca' --non-interactive"

    print(cmd + "\n", flush=True)

    p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    p.communicate()

    returnCode = p.returncode
    print(f"Return code of update is: {returnCode}\n", flush=True)

    return returnCode

def get_revision(path):
    print(f"svnversion {path}", flush=True)
    p = subprocess.Popen(f"svnversion {path}", shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    (stdout, stderr) = p.communicate()
    revision = stdout.decode().strip()
    print(f"Revision is: {revision}", flush=True)
    return revision

svnExternalFileCache = svnExternalFile + ".cache"
if (useCacheCompare and os.path.exists(svnExternalFileCache)):
    if (filecmp.cmp(svnExternalFile, svnExternalFile)):
        print(f"Files '{svnExternalFile}' and '{svnExternalFileCache}' are identical")
        sys.exit(0)
    else:
        print(f"Files '{svnExternalFile}' and '{svnExternalFileCache}' differ (or cache is not existent).")
   
# Using for loop
for line in file:
    array = line.split(" ")
    url_revision_part = array[0]
    array_url=url_revision_part.split("@")
    url_part=array_url[0]
    revision=array_url[1]
    dir_part = array[1]

    full_url=svn_server_url+url_part
    full_dir_path=external_path+"/"+dir_part
    full_dir_path = full_dir_path.strip()
    exists = os.path.exists(full_dir_path)

    returnCode = -1
    if not os.path.exists(full_dir_path):
        returnCode = svn_checkout(full_url, revision, full_dir_path)
    else:
        active_revision = get_revision(full_dir_path)
        if active_revision == "Unversioned directory":
            returnCode = 0
            continue
        
        if active_revision != revision:
            returnCode = svn_update(revision, full_dir_path)
        else:
            returnCode = 0

    if (returnCode != 0):
        break

# Closing file
file.close()

if (returnCode != 0):
    sys.exit(-1)

if (useCacheCompare):
    shutil.copyfile(svnExternalFile, svnExternalFileCache)