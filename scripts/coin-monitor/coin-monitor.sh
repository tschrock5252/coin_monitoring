#!/bin/bash

# Set up local script variables
    function DEFINE_VARIABLES {
        TODAYS_DATE=$(date +"%m-%d-%Y");
        TODAYS_DATE_WITH_SECONDS=$(date +"%m-%d-%Y - %H:%M:%S");
        COIN_TRACKING_DIR="/tmp/${1}_tracking";
		echo "Coin tracking dir is ${COIN_TRACKING_DIR}";
        COIN_LOGS="/var/log/tyler/${1}";
        mkdir -p "${COIN_TRACKING_DIR}";
        mkdir -p "${COIN_LOGS}";
        COIN_PRICE_LOG="${COIN_LOGS}/COIN_price.${TODAYS_DATE}.log";
        touch "${COIN_PRICE_LOG}";
        COIN_WGET_FILE="${COIN_TRACKING_DIR}/${1}.html";
        COIN_EMAIL_FILE="${COIN_TRACKING_DIR}/${1}_email.txt";
        COIN_EMAIL_COUNTER_FILE_1="${COIN_TRACKING_DIR}/${1}_email_counter1.${TODAYS_DATE}.txt";
        COIN_EMAIL_COUNTER_FILE_2="${COIN_TRACKING_DIR}/${1}_email_counter2.${TODAYS_DATE}.txt";
        COIN_EMAIL_COUNTER_FILE_3="${COIN_TRACKING_DIR}/${1}_email_counter3.${TODAYS_DATE}.txt";
        COIN_EMAIL_COUNTER_FILE_4="${COIN_TRACKING_DIR}/${1}_email_counter4.${TODAYS_DATE}.txt";
        touch "${COIN_EMAIL_COUNTER_FILE_1}" && touch "${COIN_EMAIL_COUNTER_FILE_2}" && touch "${COIN_EMAIL_COUNTER_FILE_3}" && touch "${COIN_EMAIL_COUNTER_FILE_4}";
        COIN_URL="https://crypto.com/price/${1}";
        EMAIL_TO="tschrock52@gmail.com";
        sendmail=$(command -v sendmail);
    }

# Set up a lock to prevent this script from running on top of itself if executed via cron
    function SETUP_LOCK {
        SCRIPT_FILE_NAME=$(echo $(basename $0) | sed 's/\..*$//');
        LOCK_FILE="/var/lock/${SCRIPT_FILE_NAME}.lock";
        touch "${LOCK_FILE}";
        read -r lastPID < "${LOCK_FILE}";
        [ ! -z "$lastPID" -a -d /proc/$lastPID ] && echo "" && echo "# There is another copy of this script currently running. Exiting now for safety purposes." && exit 1
        echo "${BASHPID}" > "${LOCK_FILE}";
    }

# Define the script exit function to clean up
    function FINISH {
        [ -e "${COIN_WGET_FILE}" ] && rm "${COIN_WGET_FILE}";
        [ -e "${COIN_EMAIL_FILE}" ] && rm "${COIN_EMAIL_FILE}";
    }
    trap FINISH EXIT

# Define the intro text for this script.
	echo "${TODAYS_DATE_WITH_SECONDS}";
	echo "";
    function INTRO {

        # Define the intro text for this script.
            echo "${TODAYS_DATE_WITH_SECONDS}";
            echo "";
            echo "##################################################################################";
            echo "#                                                                                #";
            echo '#                         _________        .__                                   #';
            echo '#                         \_   ___ \  ____ |__| ____                             #';
            echo '#                         /    \  \/ /  _ \|  |/    \                            #';
            echo '#                         \     \___(  <_> )  |   |  \                           #';
            echo '#                          \______  /\____/|__|___|  /                           #';
            echo '#                                 \/               \/                            #';
            echo "#                                                                                #";
            echo '#                  _____                   .__   __                              #';
            echo '#                 /     \    ____    ____  |__|_/  |_  ____ _______              #';
            echo '#                /  \ /  \  /  _ \  /    \ |  |\   __\/  _ \\_  __ \             #';
            echo '#               /    Y    \(  <_> )|   |  \|  | |  | (  <_> )|  | \/             #';
            echo '#               \____|__  / \____/ |___|  /|__| |__|  \____/ |__|                #';
            echo '#                       \/              \/                                       #';
            echo "#                                                                                #";
            echo "##################################################################################";
    }

# Define the check COIN function.
    function CHECK_COIN {

        # Download a copy of crypto.com's COIN page to parse and check what the price currently is.
            wget -q -O "${COIN_WGET_FILE}" "${COIN_URL}";

        # Determine the number of times to run the loop
            LOOP_COUNT=$(grep -o -i "aria-valuetext=" "${COIN_WGET_FILE}" | wc -l);
            LOOP_START=1;

        # Loop through the html, parsing for the COIN value.
            while [ $LOOP_START -ne $LOOP_COUNT ]; do
            # Define variables specific to this while loop.
                LOOP_START=$(($LOOP_START+1));
                COIN_VALUE=$(cat "${COIN_WGET_FILE}" | awk -F 'chakra-text' "{ print \$${LOOP_START} }" | awk -F '>' '{ print $2 }' | awk -F '<' '{ print $1 }' | xargs);
                CHECK="USD";
                EMAIL_COUNT_1=$(wc -l "${COIN_EMAIL_COUNTER_FILE_1}" | awk '{ print $1 }');
                EMAIL_COUNT_2=$(wc -l "${COIN_EMAIL_COUNTER_FILE_2}" | awk '{ print $1 }');
                EMAIL_COUNT_3=$(wc -l "${COIN_EMAIL_COUNTER_FILE_3}" | awk '{ print $1 }');
                EMAIL_COUNT_4=$(wc -l "${COIN_EMAIL_COUNTER_FILE_4}" | awk '{ print $1 }');
            # Here we are defining the values that we are our thresholds for alerting on.
			# These are passed in from the command line as the 2nd - 5th CLI arguments.
                COIN_LOWER1=${2};
                COIN_LOWER2=${3};
                COIN_LOWER3=${4};
                COIN_LOWER4=${5};
                if [[ "${COIN_VALUE}" == *"${CHECK}"* ]]; then
                    COIN_VALUE=$(echo "${COIN_VALUE}" | awk -F '$' '{ print $2 }' | awk -F " USD" '{print $1}');
                    if (( $(echo "${COIN_VALUE} < ${COIN_LOWER1}" |bc -l) )); then
                        echo "Subject: ${1} Alert Email!" > "${COIN_EMAIL_FILE}";
                        echo "We have not yet begun to take off..." >> "${COIN_EMAIL_FILE}";
                        echo "${1} value is: ${COIN_VALUE}" >> "${COIN_EMAIL_FILE}";
                    # Test if an email needs to be sent.
                        grep "We have not yet begun to take off..." "${COIN_EMAIL_FILE}";
                        if [ $? -eq 0 ] && [ $EMAIL_COUNT_1 -gt 5 ]; then
                            :;
                        else
                            ${sendmail} "${EMAIL_TO}" < "${COIN_EMAIL_FILE}";
                            echo "Email sent" >> "${COIN_EMAIL_COUNTER_FILE_1}";
                        fi
                    elif (( $(echo "${COIN_VALUE} > ${COIN_LOWER1}" |bc -l) )) || (( $(echo "${COIN_VALUE} < ${COIN_LOWER2}" |bc -l) )); then
                        echo "Subject: ${1} Alert Email!" > "${COIN_EMAIL_FILE}";
                        echo "We have started to gain some speed!" >> "${COIN_EMAIL_FILE}";
                        echo "${1} value is: ${COIN_VALUE}" >> "${COIN_EMAIL_FILE}";
                    # Test if an email needs to be sent.
                        grep "We have started to gain some speed" "${COIN_EMAIL_FILE}";
                        if [ $? -eq 0 ] && [ $EMAIL_COUNT_2 -gt 5 ]; then
                            :;
                        else
                           ${sendmail} "${EMAIL_TO}" < "${COIN_EMAIL_FILE}";
                            echo "Email sent" >> "${COIN_EMAIL_COUNTER_FILE_2}";
                        fi
                    elif (( $(echo "${COIN_VALUE} > ${COIN_LOWER2}" |bc -l) )) || (( $(echo "${COIN_VALUE} < ${COIN_LOWER3}" |bc -l) )); then
                        echo "Subject: ${1} Alert Email!" > "${COIN_EMAIL_FILE}";
                        echo "We are starting to take off!" >> "${COIN_EMAIL_FILE}";
                        echo "${1} value is: ${COIN_VALUE}" >> "${COIN_EMAIL_FILE}";
                    # Test if an email needs to be sent.
                        grep "We are starting to take off" "${COIN_EMAIL_FILE}";
                        if [ $? -eq 0 ] && [ $EMAIL_COUNT_3 -gt 5 ]; then
                            :;
                        else
                            ${sendmail} "${EMAIL_TO}" < "${COIN_EMAIL_FILE}";
                            echo "Email sent" >> "${COIN_EMAIL_COUNTER_FILE_3}";
                        fi
                    elif (( $(echo "${COIN_VALUE} > ${COIN_LOWER3}" |bc -l) )) || (( $(echo "${COIN_VALUE} < ${COIN_LOWER4}" |bc -l) )); then
                        echo "Subject: ${1} Alert Email!" > "${COIN_EMAIL_FILE}";
                        echo "We are seeing amazing flight!!" >> "${COIN_EMAIL_FILE}";
                        echo "${1} value is: ${COIN_VALUE}" >> "${COIN_EMAIL_FILE}";
                    # Test if an email needs to be sent.
                        grep "We are seeing amazing flight" "${COIN_EMAIL_FILE}";
                        if [ $? -eq 0 ] && [ $EMAIL_COUNT_4 -gt 5 ]; then
                            :;
                        else
                            ${sendmail} "${EMAIL_TO}" < "${COIN_EMAIL_FILE}";
                            echo "Email sent" >> "${COIN_EMAIL_COUNTER_FILE_4}";
                        fi
                    elif (( $(echo "${COIN_VALUE} > ${COIN_LOWER4}" |bc -l) )); then
                        echo "Subject: ${1} Alert Email!" > "${COIN_EMAIL_FILE}";
                        echo "To the moon!" >> "${COIN_EMAIL_FILE}";
                        echo "${1} value is: ${COIN_VALUE}" >> "${COIN_EMAIL_FILE}";
                    # Test if an email needs to be sent.
                        grep "To the moon" "${COIN_EMAIL_FILE}";
                        if [ $? -eq 0 ]; then
                            :;
                        else
                            ${sendmail} "${EMAIL_TO}" < "${COIN_EMAIL_FILE}";
                        fi
                    else
                        :;
                    fi
                else
                    :; # This isn't a real value we are searching for.
                fi
            done

        # Output the date/time and COIN price to the log file for tracking.
            echo "${TODAYS_DATE_WITH_SECONDS} - ${COIN_VALUE}" >> "${COIN_PRICE_LOG}";

    }

# Call all of the script functions
    DEFINE_VARIABLES ${1};
    SETUP_LOCK;
    INTRO;
    CHECK_COIN ${1} ${2} ${3} ${4} ${5};
