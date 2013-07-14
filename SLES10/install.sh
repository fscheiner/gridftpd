#!/bin/bash

# installer script

INSTALLER_GRIDFTPD_VERSION=$( cat VERSION )
INSTALLER_GRIDFTPD_OS=$( cat OS )

if [[ "$INSTALLER_GRIDFTPD_OS" == "SLES" || \
      "$INSTALLER_GRIDFTPD_OS" == "RHEL" || \
      "$INSTALLER_GRIDFTPD_OS" == "CentOS" || \
      "$INSTALLER_GRIDFTPD_OS" == "SL" ]]; then

	INSTALLER_INIT_SCRIPT_CONFIGURATION_DIR_NAME="sysconfig"
	
elif [[ "$INSTALLER_GRIDFTPD_OS" == "Debian" || \
	"$INSTALLER_GRIDFTPD_OS" == "Ubuntu" ]]; then
	
	INSTALLER_INIT_SCRIPT_CONFIGURATION_DIR_NAME="default"
fi

# defaults
#  Default settings for globus-gridftp-server. 

################################################################################
# installer configuration
################################################################################

# Prefix dir for installation.
GRIDFTPD_INSTALL_PREFIX="/"

################################################################################
#  General configuration
################################################################################

# Name of this service
GRIDFTPD_SERVICE_NAME="gridftpd"

# Binary and corresponding libs
GRIDFTPD_BIN="/usr/sbin/globus-gridftp-server"
#GRIDFTPD_LD_LIBRARY_PATH="/usr/lib"

# For self-compiled Globus GridFTP servers
GLOBUS_LOCATION="/usr"

# Path to pidfile
GRIDFTPD_PIDFILES_PATH="/var/run"

# Fully qualified domain name of this host
GRIDFTPD_HOST_FQDN=$( hostname --fqdn )

# Base dir for globus-gridftp-server configuration files
GRIDFTPD_CONFIG_BASE_PATH="/etc/${GRIDFTPD_SERVICE_NAME}/${GRIDFTPD_HOST_FQDN}"


################################################################################
# General network configuration
################################################################################

# Port ranges
GRIDFTPD_TCP_PORT_RANGE="20000,25000"
GRIDFTPD_TCP_SOURCE_RANGE="20000,25000"


################################################################################
# GSI configuration
################################################################################

# Base dir for GSI configuration (e.g. grid-mapfile, trusted CA certificates,
# host credentials, etc.)
GRIDFTPD_GSI_CONFIG_BASE_PATH="/etc/grid-security"

# grid-mapfile to use
GRIDFTPD_GRIDMAPFILE="${GRIDFTPD_GSI_CONFIG_BASE_PATH}/grid-mapfile"

# CA certificates dir
GRIDFTPD_X509_CERT_DIR="${GRIDFTPD_GSI_CONFIG_BASE_PATH}/certificates"


################################################################################
# frontend configuration
################################################################################
# user configuration
GRIDFTPD_FRONTEND_RUNASUSER="globus"

# config file
GRIDFTPD_FRONTEND_CONFIG="${GRIDFTPD_INSTALL_PREFIX}/etc/${GRIDFTPD_SERVICE_NAME}/${GRIDFTPD_HOST_FQDN}/gridftpd_frontend.conf"

# Port to listen on
GRIDFTPD_FRONTEND_PORT=2811

# certificate and key
# NOTICE:
# The following two files have to be owned by the user that runs the frontend
# service!
GRIDFTPD_FRONTEND_CERT="${GRIDFTPD_GSI_CONFIG_BASE_PATH}/hostcert_${GRIDFTPD_HOST_FQDN}_frontend.pem"
GRIDFTPD_FRONTEND_KEY="${GRIDFTPD_GSI_CONFIG_BASE_PATH}/hostkey_${GRIDFTPD_HOST_FQDN}_frontend.pem"


################################################################################
# configuration of backends
################################################################################
# number of back ends to use
GRIDFTPD_BACKENDS_NUMBER=2

# user configuration
GRIDFTPD_BACKEND_RUNASUSER="root"

# prefix of the backend config files
GRIDFTPD_BACKEND_CONFIG_PREFIX="${GRIDFTPD_INSTALL_PREFIX}/etc/${GRIDFTPD_SERVICE_NAME}/${GRIDFTPD_HOST_FQDN}/gridftpd_backend"

# backend ports (first value)
GRIDFTPD_BACKEND_PORT_FIRST=2813

#  certificate and key
#  NOTICE:
#+ The following two files have to be owned by the user that runs the backend
#+ service!
GRIDFTPD_BACKEND_CERT="${GRIDFTPD_GSI_CONFIG_BASE_PATH}/hostcert_${GRIDFTPD_HOST_FQDN}_backend.pem"
GRIDFTPD_BACKEND_KEY="${GRIDFTPD_GSI_CONFIG_BASE_PATH}/hostkey_${GRIDFTPD_HOST_FQDN}_backend.pem"

################################################################################

# If installer configuration is provided as argument...
if [[ "$1" != "" ]]; then
	# ...load configuration
	. "$1" || exit 1
else
	# main
	echo "Installing gridftpd v$INSTALLER_GRIDFTPD_VERSION for $INSTALLER_GRIDFTPD_OS..."
	echo ""
	echo "Values in [] are defaults except for Y/N questions where the capital letter is the default and can be accepted by just hitting ENTER!"
	echo ""

	echo -n "Configure (a) GridFTP back end process(es) [Y/n]: "
	read
	if [[ "$REPLY" == "" || "$REPLY" =~ [Yy] ]]; then

		INSTALLER_CONFIGURE_BACKEND="yes"
	else
		INSTALLER_CONFIGURE_BACKEND="no"
	fi
	echo ""

	echo -n "Configure a GridFTP front end process [Y/n]: "
	read
	if [[ "$REPLY" == "" || "$REPLY" =~ [Yy] ]]; then
	
		INSTALLER_CONFIGURE_FRONTEND="yes"
	else
		INSTALLER_CONFIGURE_FRONTEND="no"
	fi
	echo ""
	
	if [[ "$INSTALLER_CONFIGURE_FRONTEND" == "no" && \
	      "$INSTALLER_CONFIGURE_BACKEND" == "no" ]]; then

		echo "Neither gridftpd front end nor any back end(s) to be installed. Nothing to be done."
		exit
	fi

	########################################################################
	# General configuration
	########################################################################
	echo "GENERAL CONFIGURATION"
	echo ""

	echo -n "Please provide the full path to the install base directory for the init script. E.g. if \"/\" is used, the init script and corresponding files will be installed below \"/etc\" [$GRIDFTPD_INSTALL_PREFIX]: "
	read INSTALLER_GRIDFTPD_INSTALL_PREFIX
	# Without user input the default should be used, which is based on "/".
	# To make the output look better, the var is kept empty when "/" should
	# be used as prefix.
	#if [[ "$INSTALLER_GRIDFTPD_INSTALL_PREFIX" == "" ]]; then
	#	INSTALLER_GRIDFTPD_INSTALL_PREFIX=""
	#fi
	echo ""

	echo -n "Please provide a name for this GridFTP service (i.e. if you plan to have multiple GridFTP services on this machine, each service needs to have a different name) [$GRIDFTPD_SERVICE_NAME]: "
	read INSTALLER_GRIDFTPD_SERVICE_NAME
	if [[ "$INSTALLER_GRIDFTPD_SERVICE_NAME" == "" ]]; then
		INSTALLER_GRIDFTPD_SERVICE_NAME="$GRIDFTPD_SERVICE_NAME"
	fi
	echo ""
	
	if [[ "$INSTALLER_GRIDFTPD_INSTALL_PREFIX" != "" ]]; then
		GRIDFTPD_BIN="/sbin/globus-gridftp-server"
	fi
	echo -n "Please provide the full path to the Globus GridFTP server binary [${INSTALLER_GRIDFTPD_INSTALL_PREFIX}${GRIDFTPD_BIN}]: "
	read INSTALLER_GRIDFTPD_BIN
	if [[ "$INSTALLER_GRIDFTPD_BIN" == "" ]]; then
		INSTALLER_GRIDFTPD_BIN="${INSTALLER_GRIDFTPD_INSTALL_PREFIX}${GRIDFTPD_BIN}"
	fi
	
	INSTALLER_GRIDFTPD_LD_LIBRARY_PATH=$( dirname "$INSTALLER_GRIDFTPD_BIN" )/../lib
	INSTALLER_GRIDFTPD_PIDFILES_PATH="$GRIDFTPD_PIDFILES_PATH"
	echo ""

	echo -n "Please provide the FQDN (fully qualified domain name) to use for this service. This needs to be the same FQDN as used in the host certificates for this service. Use \"FQDN\" if this should be determined dynamically during runtime of the init script with \$(hostname --fqdn). When using \"FQDN\", please make sure that \$(hostname --fqdn) returns the correct FQDN.  [$GRIDFTPD_HOST_FQDN]: "
	read INSTALLER_GRIDFTPD_HOST_FQDN
	if [[ "$INSTALLER_GRIDFTPD_HOST_FQDN" == "" ]]; then
		INSTALLER_GRIDFTPD_HOST_FQDN="$GRIDFTPD_HOST_FQDN"
	elif [[ "$INSTALLER_GRIDFTPD_HOST_FQDN" == "FQDN" ]]; then
		INSTALLER_GRIDFTPD_HOST_FQDN="\$(hostname --fqdn)"
	fi
	echo ""

	echo -n "Please provide the base directory for gridftpd configuration files [${INSTALLER_GRIDFTPD_INSTALL_PREFIX}/etc/${INSTALLER_GRIDFTPD_SERVICE_NAME}]: "
	read INSTALLER_GRIDFTPD_CONFIG_BASE_PATH
	if [[ "$INSTALLER_GRIDFTPD_CONFIG_BASE_PATH" == "" ]]; then
		INSTALLER_GRIDFTPD_CONFIG_BASE_PATH="${INSTALLER_GRIDFTPD_INSTALL_PREFIX}/etc/${INSTALLER_GRIDFTPD_SERVICE_NAME}"
	fi
	echo ""

	########################################################################
	# Network configuration
	########################################################################
	echo "NETWORK CONFIGURATION"
	echo ""
	
	echo -n "Please define the TCP port range to use for inbound connections (GLOBUS_TCP_PORT_RANGE) [$GRIDFTPD_TCP_PORT_RANGE]: "
	read INSTALLER_GRIDFTPD_TCP_PORT_RANGE
	if [[ "$INSTALLER_GRIDFTPD_TCP_PORT_RANGE" == "" ]]; then
		INSTALLER_GRIDFTPD_TCP_PORT_RANGE="$GRIDFTPD_TCP_PORT_RANGE"
	fi
	echo ""
	
	echo -n "Please define the TCP port range to use for outbound connections (GLOBUS_TCP_SOURCE_RANGE) [$GRIDFTPD_TCP_SOURCE_RANGE]: "
	read INSTALLER_GRIDFTPD_TCP_SOURCE_RANGE
	if [[ "$INSTALLER_GRIDFTPD_TCP_SOURCE_RANGE" == "" ]]; then
		INSTALLER_GRIDFTPD_TCP_SOURCE_RANGE="$GRIDFTPD_TCP_SOURCE_RANGE"
	fi
	echo ""

	########################################################################
	# GSI configuration
	########################################################################
	echo "GSI CONFIGURATION"
	echo ""
	
	echo -n "Please provide the full path to the GSI configuration base dir [${INSTALLER_GRIDFTPD_INSTALL_PREFIX}${GRIDFTPD_GSI_CONFIG_BASE_PATH}]: "
	read INSTALLER_GRIDFTPD_GSI_CONFIG_BASE_PATH
	if [[ "$INSTALLER_GRIDFTPD_GSI_CONFIG_BASE_PATH" == "" ]]; then
		INSTALLER_GRIDFTPD_GSI_CONFIG_BASE_PATH="${INSTALLER_GRIDFTPD_INSTALL_PREFIX}${GRIDFTPD_GSI_CONFIG_BASE_PATH}"
	fi
	echo ""

	echo -n "Please provide the full path to the grid-mapfile to use for this service [${INSTALLER_GRIDFTPD_GSI_CONFIG_BASE_PATH}/grid-mapfile]: "
	read INSTALLER_GRIDFTPD_GRIDMAPFILE
	if [[ "$INSTALLER_GRIDFTPD_GRIDMAPFILE" == "" ]]; then
		INSTALLER_GRIDFTPD_GRIDMAPFILE="$INSTALLER_GRIDFTPD_GSI_CONFIG_BASE_PATH/grid-mapfile"
	fi
	echo ""

	echo -n "Please provide the full path to the trusted CA certificates dir to use for this service [${INSTALLER_GRIDFTPD_GSI_CONFIG_BASE_PATH}/certificates]: "
	read INSTALLER_GRIDFTPD_X509_CERT_DIR
	if [[ "$INSTALLER_GRIDFTPD_X509_CERT_DIR" == "" ]]; then
		INSTALLER_GRIDFTPD_X509_CERT_DIR="$INSTALLER_GRIDFTPD_GSI_CONFIG_BASE_PATH/certificates"
	fi
	echo ""

	########################################################################
	# Back end configuration
	########################################################################
	if [[ "$INSTALLER_CONFIGURE_BACKEND" == "yes" ]]; then

		echo "BACK END CONFIGURATION"
		echo ""
	
		echo -n "Please provide the number of back end processes you intend to use [$GRIDFTPD_BACKENDS_NUMBER]: "
		read INSTALLER_GRIDFTPD_BACKENDS_NUMBER
		if [[ "$INSTALLER_GRIDFTPD_BACKENDS_NUMBER" == "" ]]; then
			INSTALLER_GRIDFTPD_BACKENDS_NUMBER="$GRIDFTPD_BACKENDS_NUMBER"
		fi
		echo ""
	
		echo -n "Please provide the user name for the back end process(es) [$GRIDFTPD_BACKEND_RUNASUSER]: "
		read INSTALLER_GRIDFTPD_BACKEND_RUNASUSER
		if [[ "$INSTALLER_GRIDFTPD_BACKEND_RUNASUSER" == "" ]]; then
			INSTALLER_GRIDFTPD_BACKEND_RUNASUSER="$GRIDFTPD_BACKEND_RUNASUSER"
		fi
		echo ""
	
		echo -n "Please provide the prefix (incl. full path) for the back end configuration file(s) [${INSTALLER_GRIDFTPD_CONFIG_BASE_PATH}/gridftpd_backend]: "
		read INSTALLER_GRIDFTPD_BACKEND_CONFIG_PREFIX
		if [[ "$INSTALLER_GRIDFTPD_BACKEND_CONFIG_PREFIX" == "" ]]; then
			INSTALLER_GRIDFTPD_BACKEND_CONFIG_PREFIX="${INSTALLER_GRIDFTPD_CONFIG_BASE_PATH}/gridftpd_backend"
		fi
		echo ""
	
		echo -n "Please provide the TCP port the first back end should listen to (additional backends will use the subsequent TCP ports) [$GRIDFTPD_BACKEND_PORT_FIRST]: "
		read INSTALLER_GRIDFTPD_BACKEND_PORT_FIRST
		if [[ "$INSTALLER_GRIDFTPD_BACKEND_PORT_FIRST" == "" ]]; then
			INSTALLER_GRIDFTPD_BACKEND_PORT_FIRST="$GRIDFTPD_BACKEND_PORT_FIRST"
		fi
		echo ""


		# TODO:
		# Key and cert names should use the dynamically determined FQDN!
		echo -n "Please provide the full path to the host certificate used for the back end(s) [${INSTALLER_GRIDFTPD_GSI_CONFIG_BASE_PATH}/hostcert_${INSTALLER_GRIDFTPD_HOST_FQDN}_backend.pem]: "
		read INSTALLER_GRIDFTPD_BACKEND_CERT
		if [[ "$INSTALLER_GRIDFTPD_BACKEND_CERT" == "" ]]; then
			INSTALLER_GRIDFTPD_BACKEND_CERT="${INSTALLER_GRIDFTPD_GSI_CONFIG_BASE_PATH}/hostcert_${INSTALLER_GRIDFTPD_HOST_FQDN}_backend.pem"
		fi
		echo ""
	
		echo -n "Please provide the full path to the host key used for the back end(s) [${INSTALLER_GRIDFTPD_GSI_CONFIG_BASE_PATH}/hostkey_${INSTALLER_GRIDFTPD_HOST_FQDN}_backend.pem]: "
		read INSTALLER_GRIDFTPD_BACKEND_KEY
		if [[ "$INSTALLER_GRIDFTPD_BACKEND_KEY" == "" ]]; then
			INSTALLER_GRIDFTPD_BACKEND_KEY="${INSTALLER_GRIDFTPD_GSI_CONFIG_BASE_PATH}/hostkey_${INSTALLER_GRIDFTPD_HOST_FQDN}_backend.pem"
		fi
		echo ""
	fi
	
	########################################################################
	# Front end configuration
	########################################################################
	if [[ "$INSTALLER_CONFIGURE_FRONTEND" == "yes" ]]; then
	
		echo "FRONT END CONFIGURATION"
		echo ""

		echo -n "Please provide the user name for the front end process [$GRIDFTPD_FRONTEND_RUNASUSER]: "
		read INSTALLER_GRIDFTPD_FRONTEND_RUNASUSER
		if [[ "$INSTALLER_GRIDFTPD_FRONTEND_RUNASUSER" == "" ]]; then
			INSTALLER_GRIDFTPD_FRONTEND_RUNASUSER="$GRIDFTPD_FRONTEND_RUNASUSER"
		fi
		echo ""
	
		echo -n "Please provide the full path to the front end configuration file [${INSTALLER_GRIDFTPD_CONFIG_BASE_PATH}/gridftpd_frontend.conf]: "
		read INSTALLER_GRIDFTPD_FRONTEND_CONFIG
		if [[ "$INSTALLER_GRIDFTPD_FRONTEND_CONFIG" == "" ]]; then
			INSTALLER_GRIDFTPD_FRONTEND_CONFIG="${INSTALLER_GRIDFTPD_CONFIG_BASE_PATH}/gridftpd_frontend.conf"
		fi
		echo ""
	
		echo -n "Please provide the TCP port the front end should listen to [$GRIDFTPD_FRONTEND_PORT]: "
		read INSTALLER_GRIDFTPD_FRONTEND_PORT
		if [[ "$INSTALLER_GRIDFTPD_FRONTEND_PORT" == "" ]]; then
			INSTALLER_GRIDFTPD_FRONTEND_PORT="$GRIDFTPD_FRONTEND_PORT"
		fi
		echo ""
	
		echo -n "Please provide the full path to the host certificate used for the front end [${INSTALLER_GRIDFTPD_GSI_CONFIG_BASE_PATH}/hostcert_${INSTALLER_GRIDFTPD_HOST_FQDN}_frontend.pem]: "
		read INSTALLER_GRIDFTPD_FRONTEND_CERT
		if [[ "$INSTALLER_GRIDFTPD_FRONTEND_CERT" == "" ]]; then
			INSTALLER_GRIDFTPD_FRONTEND_CERT="${INSTALLER_GRIDFTPD_GSI_CONFIG_BASE_PATH}/hostcert_${INSTALLER_GRIDFTPD_HOST_FQDN}_frontend.pem"
		fi
		echo ""
	
		echo -n "Please provide the full path to the host key used for the front end [${INSTALLER_GRIDFTPD_GSI_CONFIG_BASE_PATH}/hostkey_${INSTALLER_GRIDFTPD_HOST_FQDN}_frontend.pem]: "
		read INSTALLER_GRIDFTPD_FRONTEND_KEY
		if [[ "$INSTALLER_GRIDFTPD_FRONTEND_KEY" == "" ]]; then
			INSTALLER_GRIDFTPD_FRONTEND_KEY="${INSTALLER_GRIDFTPD_GSI_CONFIG_BASE_PATH}/hostkey_${INSTALLER_GRIDFTPD_HOST_FQDN}_frontend.pem"
		fi
		echo ""
		
		echo -n "Please provide any additional GridFTP back end(s) this front end should use (<FQDN>:<PORT>[,<FQDN>:<PORT>[,[...]]]): "
		read INSTALLER_GRIDFTPD_ADDITIONAL_BACKENDS
	fi

fi

################################################################################
# actual installation      
################################################################################
if [[ ! -e "$INSTALLER_GRIDFTPD_CONFIG_BASE_PATH" ]]; then

	mkdir -p "$INSTALLER_GRIDFTPD_CONFIG_BASE_PATH"
fi

if [[ "$INSTALLER_CONFIGURE_BACKEND" == "yes" ]]; then

	for INDEX in $( seq -w 1 $INSTALLER_GRIDFTPD_BACKENDS_NUMBER ); do
	
		INSTALLER_GRIDFTPD_BACKEND_CONFIG="${INSTALLER_GRIDFTPD_BACKEND_CONFIG_PREFIX}_#${INDEX}.conf"
		cp ./etc/gridftpd/FQDN/gridftpd_backend.conf "$INSTALLER_GRIDFTPD_BACKEND_CONFIG"
		# create configuration dir (NOTICE: The globus-gridftp-server
		# seems to periodically check this dir for (new) files. This
		# means, that reconfigurations done in this dir will be effective
		# without reloading the GridFTP service with the init script.
		# But remember that the main configuration file is always loaded
		# last. So configurations made there will override configurations
		# made in the configuration dir.)
		mkdir "${INSTALLER_GRIDFTPD_BACKEND_CONFIG}.d"
	done
fi

if [[ "$INSTALLER_CONFIGURE_FRONTEND" == "yes" ]]; then
	
	# copy default configuration
	cp ./etc/gridftpd/FQDN/gridftpd_frontend.conf "$INSTALLER_GRIDFTPD_FRONTEND_CONFIG"
	# create configuration dir (NOTICE: The globus-gridftp-server
	# seems to periodically check this dir for (new) files. This
	# means, that reconfigurations done in this dir will be effective
	# without reloading the GridFTP service with the init script.
	# But remember that the main configuration file is always loaded
	# last. So configurations made there will override configurations
	# made in the configuration dir.)
	mkdir -p "${INSTALLER_GRIDFTPD_FRONTEND_CONFIG}.d"
	
fi

################################################################################
# install init script and build init script configuration
################################################################################
if [[ ! -e "${INSTALLER_GRIDFTPD_INSTALL_PREFIX}/etc/init.d" ]]; then

	mkdir -p "${INSTALLER_GRIDFTPD_INSTALL_PREFIX}/etc/init.d"
fi

INSTALLER_INIT_SCRIPT="${INSTALLER_GRIDFTPD_INSTALL_PREFIX}/etc/init.d/${INSTALLER_GRIDFTPD_SERVICE_NAME}"

cp "./etc/init.d/gridftpd" "$INSTALLER_INIT_SCRIPT"

# build init script configuration
if [[ ! -e "${INSTALLER_GRIDFTPD_INSTALL_PREFIX}/etc/${INSTALLER_INIT_SCRIPT_CONFIGURATION_DIR_NAME}" ]]; then

	mkdir -p "${INSTALLER_GRIDFTPD_INSTALL_PREFIX}/etc/${INSTALLER_INIT_SCRIPT_CONFIGURATION_DIR_NAME}"
fi

# TODO:
# Modify the init script configuration file so that derived vars are expanded
# during execution. This makes it easier to modify the configuration file after
# installation, as only some of the variable values need to be changed.
INSTALLER_INIT_SCRIPT_CONFIGURATION="${INSTALLER_GRIDFTPD_INSTALL_PREFIX}/etc/${INSTALLER_INIT_SCRIPT_CONFIGURATION_DIR_NAME}/${INSTALLER_GRIDFTPD_SERVICE_NAME}"

cat > "$INSTALLER_INIT_SCRIPT_CONFIGURATION" <<EOF
# gridftpd settings

################################################################################
# General configuration
################################################################################

# Binary and corresponding libs
GRIDFTPD_BIN="$INSTALLER_GRIDFTPD_BIN"
GRIDFTPD_LD_LIBRARY_PATH="$( dirname $INSTALLER_GRIDFTPD_BIN )/../lib"

# For self-compiled Globus GridFTP servers
GLOBUS_LOCATION="$( dirname $INSTALLER_GRIDFTPD_BIN )/.."

# Path to pidfile
GRIDFTPD_PIDFILES_PATH="${INSTALLER_GRIDFTPD_INSTALL_PREFIX}/var/run/${INSTALLER_GRIDFTPD_SERVICE_NAME}"

# Base dir for globus-gridftp-server configuration files
GRIDFTPD_CONFIG_BASE_PATH="$INSTALLER_GRIDFTPD_CONFIG_BASE_PATH"


################################################################################
# General network configuration
################################################################################

# Fully qualified domain name of this host
GRIDFTPD_HOST_FQDN="$INSTALLER_GRIDFTPD_HOST_FQDN"

# Port ranges
GRIDFTPD_TCP_PORT_RANGE="$INSTALLER_GRIDFTPD_TCP_PORT_RANGE"
GRIDFTPD_TCP_SOURCE_RANGE="$INSTALLER_GRIDFTPD_TCP_SOURCE_RANGE"


################################################################################
# GSI configuration
################################################################################

# Base dir for GSI configuration (e.g. grid-mapfile, trusted CA certificates,
# host credentials, etc.)
GRIDFTPD_GSI_CONFIG_BASE_PATH="$INSTALLER_GRIDFTPD_GSI_CONFIG_BASE_PATH"

# grid-mapfile to use
GRIDFTPD_GRIDMAPFILE="$INSTALLER_GRIDFTPD_GRIDMAPFILE"

# CA certificates dir
GRIDFTPD_X509_CERT_DIR="$INSTALLER_GRIDFTPD_X509_CERT_DIR"


################################################################################
# frontend configuration
################################################################################
# user configuration
GRIDFTPD_FRONTEND_RUNASUSER="$INSTALLER_GRIDFTPD_FRONTEND_RUNASUSER"

# config file
GRIDFTPD_FRONTEND_CONFIG="$INSTALLER_GRIDFTPD_FRONTEND_CONFIG"

# Port to listen on
GRIDFTPD_FRONTEND_PORT=$INSTALLER_GRIDFTPD_FRONTEND_PORT

# certificate and key
# NOTICE:
# The following two files have to be owned by the user that runs the frontend
# service!
GRIDFTPD_FRONTEND_CERT="$INSTALLER_GRIDFTPD_FRONTEND_CERT"
GRIDFTPD_FRONTEND_KEY="$INSTALLER_GRIDFTPD_FRONTEND_KEY"

GRIDFTPD_ADDITIONAL_BACKENDS="${INSTALLER_GRIDFTPD_ADDITIONAL_BACKENDS}"

################################################################################
#  configuration of backends
################################################################################
# number of back ends to use
GRIDFTPD_BACKENDS_NUMBER="$INSTALLER_GRIDFTPD_BACKENDS_NUMBER"

#  user configuration
GRIDFTPD_BACKEND_RUNASUSER="$INSTALLER_GRIDFTPD_BACKEND_RUNASUSER"

#  prefix of the backend config files
#  NOTICE:
#+ There can be multiple backends!
GRIDFTPD_BACKEND_CONFIG_PREFIX="$INSTALLER_GRIDFTPD_BACKEND_CONFIG_PREFIX"

# Ports to listen on
GRIDFTPD_BACKEND_PORT_FIRST=$INSTALLER_GRIDFTPD_BACKEND_PORT_FIRST

#  certificate and key
#  NOTICE:
#+ The following two files have to be owned by the user that runs the backend
#+ service!
GRIDFTPD_BACKEND_CERT="$INSTALLER_GRIDFTPD_BACKEND_CERT"
GRIDFTPD_BACKEND_KEY="$INSTALLER_GRIDFTPD_BACKEND_KEY"

EOF

# inject path to init script configuration into init script
sed -e "s|<INIT_SCRIPT_CONFIGURATION>|$INSTALLER_INIT_SCRIPT_CONFIGURATION|" -i "$INSTALLER_INIT_SCRIPT"

sed -e "s|<GRIDFTPD_SERVICE_NAME>|$INSTALLER_GRIDFTPD_SERVICE_NAME|" -i "$INSTALLER_INIT_SCRIPT"
sed -e "s|<GRIDFTPD_OS>|$INSTALLER_GRIDFTPD_OS|" -i "$INSTALLER_INIT_SCRIPT"

sed -e "s/#sed#//g" -i "$INSTALLER_INIT_SCRIPT"

echo ""
echo "Installation finished."

exit

