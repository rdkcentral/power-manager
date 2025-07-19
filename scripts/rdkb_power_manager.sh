#!/bin/sh
##########################################################################
# If not stated otherwise in this file or this component's Licenses.txt
# file the following copyright and licenses apply:
#
# Copyright 2016 RDK Management
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
##########################################################################

#------------------------------------------------------------------
#   This file contains the code to perform an orderly shutdown and startup
#   of the RDKB CCSP components.
#------------------------------------------------------------------

if [ -f /etc/device.properties ]
then
    source /etc/device.properties
fi

function usage()
{
  if [ "$XBB_SUPPORT" == "true" ] || [ "$MODEL_NUM" = "CGA4332COM" ]; then
  	echo 'Usage : rdkb_power_manager.sh <power mode>'
  	echo '        where <power mode> = POWER_TRANS_AC, POWER_TRANS_BATTERY, POWER_TRANS_HOT, POWER_TRANS_COOLED'
  else
  	echo 'Usage : rdkb_power_manager.sh <power mode>'
  	echo '        where <power mode> = POWER_TRANS_AC, POWER_TRANS_HOT, POWER_TRANS_COOLED'
  fi
  exit 1
}

function PwrMgr_TearDownComponents()
{
    # We have to perform an ordely shutdown of the RDKB components.
    # At the very least we need to shutdown SelfHeal, CcspWifiSsp, CcspMoCa, CcspLMLite, DCA, webui and 
    # any process monitoring that may restart those processes.
    #
    # If possible we need to keep CcspPandM, CcspCrSsp and WebPA for remote battery monitoring and
    # CcspMtaAgent for voice service.
    
    # Return 0 for Succes, Return 1 for failure.
    systemctl stop harvester.service
    systemctl stop CcspLMLite.service
    if [ "$OneWiFiEnabled" == "true" ]; then
	    systemctl stop onewifi_selfheal.service
	    systemctl stop onewifi.service
            sh /usr/ccsp/wifi/OneWiFi_vap_down.sh &
            echo "Device in LPM, bringing wifi vaps down" >> $"/rdklogs/logs/wifi_selfheal.txt"
    else
	    systemctl stop ccspwifiagent.service
    fi
    systemctl stop CcspMoca.service

    exit 0
}

function PwrMgr_StartupComponents()
{
    # We have to perform an orderly start of the RDKB components. Basically we have to start
    # the processes that we shut down above in the correct order.

    # Return 0 for Succes, Return 1 for failure.
    systemctl start CcspMoca.service
    if [ "$OneWiFiEnabled" == "true" ]; then
            systemctl start onewifi.service
	    systemctl start onewifi_selfheal.service
    else
            systemctl start ccspwifiagent.service
    fi
    systemctl start CcspLMLite.service
    systemctl start harvester.service

    exit 0
}

if [ "$#" -ne 1 ]; then
  usage
fi

PWRMODE=$1

if [ "$PWRMODE" = "" ]; then
    usage
elif [ "$PWRMODE" == "POWER_TRANS_AC" ]; then
    PwrMgr_StartupComponents
elif [ "$PWRMODE" == "POWER_TRANS_BATTERY" ]; then
    if [ "$XBB_SUPPORT" == "true" ] || [ "$MODEL_NUM" = "CGA4332COM" ]; then
    	PwrMgr_TearDownComponents
    else
    	usage
    fi
elif [ "$PWRMODE" == "POWER_TRANS_HOT" ]; then
    	PwrMgr_TearDownComponents
elif [ "$PWRMODE" == "POWER_TRANS_COOLED" ]; then
    PwrMgr_StartupComponents
else
    usage
fi
