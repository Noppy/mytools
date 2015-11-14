#!/bin/bash -x

export LANG=C
export PATH=:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:

RPMBUILD_DIR=/data/rpmbuild
SQUASHFS_DIR=/data/squashfs
HTTP_HTML_DIR=/data/html
HTTP_HTML_TOOLS_DIR="${HTTP_HTML_DIR}/tools"
SOURCE_DIR=/data/source

#check rpm package
SRPM_FILE=$1
if [ ! -f "${SRPM_FILE}" ]; then
    echo "not found \"${SRPM_FILE}\" srpm file."
    exit
elif [ `file "${SRPM_FILE}" | grep -ce "RPM v3.0 src"` = 0 ]; then
    echo "\"${SRPM_FILE}\" is not SRPM file!"
    exit
fi

#chkeck & create ${RPMBUILD_DIR}
if [ ! -d "${RPMBUILD_DIR}" ]; then
    mkdir ${RPMBUILD_DIR}
    if [ $? != 0 -o ! -d "${RPMBUILD_DIR}" ]; then
        echo "can not create ${RPMBUILD_DIR} directory."
        exit
    fi
fi

#clear ${RPMBUILD_DIR}
echo "remove data at ${RPMBUILD_DIR}"
rm -rf ${RPMBUILD_DIR}/*

#check symbolic link
if [ ! -h ~/rpmbuild ]; then
    if [ -d ~/rpmbuild ]; then
        echo "exist ~/rpmbuild directory."
        exit
    fi
    ln -s ${RPMBUILD_DIR} ~/rpmbuild
    if [ $? != 0 -o ! -h ~/rpmbuild ]; then
        echo "can not create symbolic link."
        exit
    fi
fi

SRPM_NAME=`rpm -q --qf=%{NAME} -p ${SRPM_FILE} 2>/dev/null`
SRPM_VERSION=`rpm -q --qf=%{VERSION}-%{RELEASE} -p ${SRPM_FILE} 2>/dev/null`

#install SRPM package
rpm -ivh ${SRPM_FILE}

#check the SPEC file.
SPEC=${RPMBUILD_DIR}/SPECS/*.spec
if [ ! -f ${SPEC} ]; then
    echo "not found SPEC file(${SPEC})."
    exit
fi

#extract (unpack sources and apply patches)
rpmbuild --nodeps -bp ${SPEC}

#change directory
BUILD_SOURCE_TOP=${RPMBUILD_DIR}/BUILD/*/
if [ ! -d ${BUILD_SOURCE_TOP} ]; then
    echo "not found BUILD_TOP(${BUILD_SOURCE_TOP})"
    exit
fi
echo "change directory => ${BUILD_SOURCE_TOP}"
cd ${BUILD_SOURCE_TOP}


#htags
echo "generates HTML os source code."
htags --gtags --frame --alphabet --line-number --symbol -other \
      --main-func main --title "${SRPM_NAME}-${SRPM_VERSION}";

#move html files.
echo "move generated HTML files"
mv ./HTML "${HTTP_HTML_TOOLS_DIR}/${SRPM_NAME}-${SRPM_VERSION}"


#source
echo "remove global data"
rm -rf HTML
rm -f  GPATH GRTAGS GTAGS
echo "move source codes"
MOVE_DIR=`pwd`
cd ../
mv "${MOVE_DIR}" "${SOURCE_DIR}/${SRPM_NAME}-${SRPM_VERSION}"
