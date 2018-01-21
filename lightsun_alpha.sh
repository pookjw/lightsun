#!/bin/sh
# lightsun
TOOL_VERSION=1
TOOL_BUILD=alpha
SEEDUTIL_COMMAND="sudo /System/Library/PrivateFrameworks/Seeding.framework/Versions/A/Resources/seedutil"

function setProjectPath(){
	COUNT=1
	while(true); do
		if [[ -d "/tmp/lightsun/${COUNT}" ]]; then
			COUNT=$((COUNT+1))
		else
			mkdir -p "/tmp/lightsun/${COUNT}"
			PROJECT_DIR="/tmp/lightsun/${COUNT}"
			break
		fi
	done
	mkdir -p "${PROJECT_DIR}/TitleBar"
}

function showInferface(){
	addTitleBar "Home"
	while(true); do
		clear
		showLines "*"
		echo "lightsun (Version: ${TOOL_VERSION}) by pookjw"
		showLines "-"
		if [[ -z "${PLATFORM}" ]]; then
			echo "(1) Platform: (undefined)"
		else
			echo "(1) Platform: ${PLATFORM}"
		fi
		if [[ -z "${VERSION}" ]]; then
			echo "(2) Version: (undefined)"
		else
			echo "(2) Version: ${VERSION}"
		fi
		if [[ -z "${BUILD}" ]]; then
			echo "(3) Build: (undefined)"
		else
			echo "(3) Build: ${BUILD}"
		fi
		if [[ -z "${CATALOG}" ]]; then
			echo "(4) Catalog: (undefined)"
		else
			echo "(4) Catalog: ${CATALOG}"
		fi
		if [[ -z "${PREREQUISITE_VERISON}" ]]; then
			echo "(5) Version (Prerequisite): (undefined)"
		else
			echo "(5) Version (Prerequisite): ${PREREQUISITE_VERISON}"
		fi
		if [[ ! "${PLATFORM}" == macOS ]]; then
			if [[ -z "${PREREQUISITE_BUILD}" ]]; then
				echo "(6) Build (Prerequisite): (undefined)"
			else
				echo "(6) Build (Prerequisite): ${PREREQUISITE_BUILD}"
			fi
			showLines "-"
			echo "commands: 1~6, adv, back, exit, start"
		else
			showLines "-"
			echo "commands: 1~5, adv, back, exit, start"
		fi
		showLines "*"
		readAnswer

		if [[ "${ANSWER}" == 1 ]]; then
			addTitleBar "Set Platform"
			while(true); do
				clear
				showLines "*"
				showTitleBar
				showLines "-"
				echo "(1) macOS"
				echo "(2) The others (iOS, tvOS, etc...)"
				showLines "*"
				readAnswer

				if [[ "${ANSWER}" == 1 ]]; then
					PLATFORM=macOS
					CATALOG=
					backTitleBar
					break
				elif [[ "${ANSWER}" == 2 ]]; then
					PLATFORM=TheOthers
					CATALOG=
					backTitleBar
					break
				else
					replyAnswer
				fi
			done
		elif [[ "${ANSWER}" == 2 ]]; then
			readAnswer "VERSION=" VERSION
		elif [[ "${ANSWER}" == 3 ]]; then
			readAnswer "BUILD=" BUILD
		elif [[ "${ANSWER}" == 4 ]]; then
			addTitleBar "Set catalog"
			if [[ -z "${PLATFORM}" ]]; then
				showError "Define Platform first."
				backTitleBar
				showPA2C
			else
				while(true); do
					clear
					showLines "*"
					showTitleBar
					showLines "-"

					if [[ "${PLATFORM}" == macOS ]]; then
						echo "(1) Detect from this macOS"
					else
						echo "(1) Detect from OTA Profile (.mobileconfig)"
					fi
					echo "(2) Enter URL manually"
					showLines "*"
					readAnswer

					if [[ "${ANSWER}" == 1 ]]; then
						detectCatalog
						if [[ -z "${CATALOG}" ]]; then
							showError "Failed to detect catalog."
							showPA2C
						else
							backTitleBar
							break
						fi
					elif [[ "${ANSWER}" == 2 ]]; then
						readAnswer "CATALOG=" CATALOG
						backTitleBar
						break
					else
						replyAnswer
					fi
				done
			fi
		elif [[ "${ANSWER}" == 5 ]]; then
			readAnswer "PREREQUISITE_VERISON=" PREREQUISITE_VERISON
		elif [[ "${ANSWER}" == 6 ]]; then
			if [[ "${PLATFORM}" == macOS ]]; then
				showNotSupportedCommand
			else
				readAnswer "PREREQUISITE_BUILD=" PREREQUISITE_BUILD
			fi
		elif [[ "${ANSWER}" == adv ]]; then
			showAdvancedSettings
		else
			replyAnswer
		fi
	done
}

function detectCatalog(){
	if [[ "${PLATFORM}" == macOS ]]; then
		CURRENT_ENROLLED_SEED=$(${SEEDUTIL_COMMAND} current | grep "Currently enrolled in" | cut -d" " -f4)
		echo "Currently enrolled in: ${CURRENT_ENROLLED_SEED}"
		if [[ "${CURRENT_ENROLLED_SEED}" == "(null)" ]]; then
			${SEEDUTIL_COMMAND} enroll DeveloperSeed > /dev/null 2>&1
		fi
		CATALOG=$(sudo /System/Library/PrivateFrameworks/Seeding.framework/Versions/A/Resources/seedutil current | grep CatalogURL | cut -d" " -f2)
		echo "CatalogURL: ${CATALOG}"
		if [[ "${CURRENT_ENROLLED_SEED}" == "(null)" ]]; then
			${SEEDUTIL_COMMAND} unenroll > /dev/null 2>&1
		fi
	else
		:
	fi
	showPA2C
}

function readAnswer(){
	if [[ -z "${1}" ]]; then
		read -p "- " ANSWER
	else
		if [[ -z "${2}" ]]; then
			read -p "${1}" ANSWER
		else
			read -p "${1}" "${2}"
		fi
	fi
}

function replyAnswer(){
	if [[ "${ANSWER}" == back || "${ANSWER}" == q ]]; then
		if [[ "$(showTitleBar)" == Home ]]; then
			showNotSupportedCommand
		else
			backTitleBar
			break
		fi
	elif [[ "${ANSWER}" == exit ]]; then
		quitTool 0
	elif [[ "${ANSWER}" == adv ]]; then
		showAdvancedSettings
	elif [[ -z "${ANSWER}" ]]; then
		:
	else
		showNotSupportedCommand
	fi
}

function showAdvancedSettings(){
	addTitleBar "Advanced Settings"
	while(true); do
		clear
		showLines "*"
		showTitleBar
		showLines "-"
		echo "(1) Run addTitleBar"
		echo "(2) Run backTitleBar"
		echo "(3) Enroll to DeveloperSeed"
		echo "(4) Enroll to PublicSeed"
		echo "(5) Unenroll Seed"
		showLines "-"
		echo "PROJECT_DIR=${PROJECT_DIR}"
		echo "TITLE_NUM=${TITLE_NUM}"
		showLines "*"
		readAnswer

		if [[ "${ANSWER}" == 1 ]]; then
			addTitleBar "$(readAnswer "$ addTitleBar "; echo "${ANSWER}")"
		elif [[ "${ANSWER}" == 2 ]]; then
			backTitleBar
		elif [[ "${ANSWER}" == 3 ]]; then
			${SEEDUTIL_COMMAND} enroll DeveloperSeed
		elif [[ "${ANSWER}" == 4 ]]; then
			${SEEDUTIL_COMMAND} enroll PublicSeed
		elif [[ "${ANSWER}" == 5 ]]; then
			${SEEDUTIL_COMMAND} unenroll
		else
			replyAnswer
		fi
	done
}

function showError(){
	if [[ -z "${1}" ]]; then
		echo "ERROR!"
	else
		echo "ERROR: ${1}"
	fi
}

function showNotSupportedCommand(){
	echo "Not supported command: ${ANSWER}"
	showPA2C
}

function showLines(){
	PRINTED_COUNTS=0
	COLS=`tput cols`
	if [[ "${COLS}" -ge 1 ]]; then
		while [[ ! $PRINTED_COUNTS == $COLS ]]; do
			printf "${1}"
			PRINTED_COUNTS=$((${PRINTED_COUNTS}+1))
		done
		echo
	fi
}

function showPA2C(){
	read -s -n 1 -p "Press any key to continue..."
	echo
}

function showTitleBar(){
	if [[ -f "${PROJECT_DIR}/TitleBar/${TITLE_NUM}" ]]; then
		cat "${PROJECT_DIR}/TitleBar/${TITLE_NUM}"
	else
		echo "Title"
	fi
}

function addTitleBar(){
	if [[ -z "${TITLE_NUM}" ]]; then
		TITLE_NUM=1
	fi
	if [[ ! -z "${1}" ]]; then
		if [[ -z "$(ls "${PROJECT_DIR}/TitleBar")" ]]; then
			echo "${1}" >> "${PROJECT_DIR}/TitleBar/${TITLE_NUM}"
		else
			echo "$(showTitleBar) > ${1}" >> "${PROJECT_DIR}/TitleBar/$((${TITLE_NUM}+1))"
			TITLE_NUM=$((${TITLE_NUM}+1))
		fi
	fi
}

function backTitleBar(){
	if [[ -f "${PROJECT_DIR}/TitleBar/${TITLE_NUM}" ]]; then
		rm "${PROJECT_DIR}/TitleBar/${TITLE_NUM}"
	fi
	TITLE_NUM=$((${TITLE_NUM}-1))
}

function deleteFile(){
	if [[ ! -z "${1}" ]]; then
		if [[ -f "${1}" ]]; then
			rm "${1}"
		elif [[ -d "${1}" ]]; then
			rm -rf "${1}"
		fi
	fi
}

function quitTool(){
	deleteFile "${PROJECT_DIR}"
	exit "${1}"
}

setProjectPath
showInferface
