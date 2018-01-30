#!/bin/sh
# lightsun
TOOL_VERSION=11
TOOL_BUILD=alpha
SEEDUTIL_COMMAND="sudo /System/Library/PrivateFrameworks/Seeding.framework/Versions/A/Resources/seedutil"

function setDefaultSettings(){
	#PLATFORM=macOS
	#CATALOG=https://swscan.apple.com/content/catalogs/others/index-10.13seed-10.13-10.12-10.11-10.10-10.9-mountainlion-lion-snowleopard-leopard.merged-1.sucatalog.gz
	#VERSION=10.13.4
	#BUILD=17E139j
	:
}

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
	mkdir -p "${PROJECT_DIR}/data"
	mkdir -p "${PROJECT_DIR}/TitleBar"
}

function showInferface(){
	addTitleBar "Home"
	while(true); do
		clear
		showLines "*"
		showTitleBar
		showLines "-"
		if [[ -z "${PLATFORM}" ]]; then
			echo "(1) Platform : ${RED}(undefined)${NC}"
		else
			echo "(1) Platform : ${BLUE}${PLATFORM}${NC}"
		fi
		if [[ -z "${DEVICE}" ]]; then
			echo "(2) Device: (undefined)"
		else
			echo "(2) Device: ${BLUE}${DEVICE}${NC}"
		fi
		if [[ -z "${VERSION}" ]]; then
			echo "(3) Version: (undefined)"
		else
			echo "(3) Version: ${BLUE}${VERSION}${NC}"
		fi
		if [[ -z "${BUILD}" ]]; then
			echo "(4) Build: (undefined)"
		else
			echo "(4) Build: ${BLUE}${BUILD}${NC}"
		fi
		if [[ ! "${PLATFORM}" == watchOS || ! "${PARSE_DOCUMENTATION_ONLY}" == YES ]]; then
			if [[ -z "${CATALOG}" ]]; then
				echo "(5) Catalog : ${RED}(undefined)${NC}"
			else
				echo "(5) Catalog : ${BLUE}${CATALOG}${NC}"
			fi
		fi
		if [[ ! "${PLATFORM}" == macOS ]]; then
			if [[ -z "${INTERNAL_BUILD_NAME}" ]]; then
				echo "(6) Documentation ID : (undefined)"
			else
				echo "(6) Documentation ID : ${BLUE}${INTERNAL_BUILD_NAME}${NC}"
			fi
		fi
		if [[ ! "${PLATFORM}" == macOS && ! "${PARSE_DOCUMENTATION_ONLY}" == YES ]]; then
			if [[ -z "${PREREQUISITE_VERISON}" ]]; then
				echo "(7) Prerequisite Version : (undefined)"
			else
				echo "(7) Prerequisite Version : ${BLUE}${PREREQUISITE_VERISON}${NC}"
			fi
			if [[ -z "${PREREQUISITE_BUILD}" ]]; then
				echo "(8) Prerequisite Build : (undefined)"
			else
				echo "(8) Prerequisite Build : ${BLUE}${PREREQUISITE_BUILD}${NC}"
			fi
		fi
		showLines "-"
		echo "lightsun_${TOOL_BUILD}-${TOOL_VERSION} by pookjw"
		echo "commands: ${BLUE}*${NC}number${BLUE}*${NC}, adv, back, exit, reset, start"
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
				echo "(2) iOS, tvOS, etc..."
				echo "(3) watchOS"
				showLines "*"
				readAnswer

				if [[ "${ANSWER}" == 1 ]]; then
					resetValues
					PLATFORM=macOS
					if [[ "${PARSE_DOCUMENTATION_ONLY}" == YES ]]; then
						echo "PARSE_DOCUMENTATION_ONLY=NO"
						showPA2C
					fi
					backTitleBar
					break
				elif [[ "${ANSWER}" == 2 ]]; then
					resetValues
					PLATFORM=etc
					backTitleBar
					break
				elif [[ "${ANSWER}" == 3 ]]; then
					resetValues
					PLATFORM=watchOS
					backTitleBar
					break
				else
					replyAnswer
				fi
			done
		elif [[ "${ANSWER}" == 2 ]]; then
			if [[ "${PLATFORM}" == macOS ]]; then
				addTitleBar "Set Device"
				while(true); do
					clear
					showLines "*"
					showTitleBar
					showLines "-"
					echo "(1) Set as this machine ($(sysctl -n hw.model))"
					echo "(2) Enter manually"
					showLines "*"
					readAnswer

					if [[ "${ANSWER}" == 1 ]]; then
						DEVICE="$(sysctl -n hw.model)"
						backTitleBar
						break
					elif [[ "${ANSWER}" == 2 ]]; then
						readAnswer "DEVICE=" DEVICE
						backTitleBar
						break
					else
						replyAnswer
					fi
				done
			else
				readAnswer "DEVICE=" DEVICE
			fi
		elif [[ "${ANSWER}" == 3 ]]; then
			if [[ "${PLATFORM}" == macOS ]]; then
				addTitleBar "Set Version"
				while(true); do
					clear
					showLines "*"
					showTitleBar
					showLines "-"
					echo "(1) Set as this macOS ($(sw_vers -productVersion))"
					echo "(2) Enter manually"
					showLines "*"
					readAnswer

					if [[ "${ANSWER}" == 1 ]]; then
						VERSION="$(sw_vers -productVersion)"
						backTitleBar
						break
					elif [[ "${ANSWER}" == 2 ]]; then
						readAnswer "VERSION=" VERSION
						backTitleBar
						break
					else
						replyAnswer
					fi
				done
			else
				readAnswer "VERSION=" VERSION
			fi
		elif [[ "${ANSWER}" == 4 ]]; then
			if [[ "${PLATFORM}" == macOS ]]; then
				addTitleBar "Set Build"
				while(true); do
					clear
					showLines "*"
					showTitleBar
					showLines "-"
					echo "(1) Set as this macOS ($(sw_vers -buildVersion))"
					echo "(2) Enter manually"
					showLines "*"
					readAnswer

					if [[ "${ANSWER}" == 1 ]]; then
						BUILD="$(sw_vers -buildVersion)"
						backTitleBar
						break
					elif [[ "${ANSWER}" == 2 ]]; then
						readAnswer "BUILD=" BUILD
						backTitleBar
						break
					else
						replyAnswer
					fi
				done
			else
				readAnswer "BUILD=" BUILD
			fi
		elif [[ "${ANSWER}" == 5 ]]; then
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
					echo "(2) Enter URL manually."
					if [[ ! "${PLATFORM}" == macOS ]]; then
						echo "(3) See list of URL (only for non-macOS)"
					fi
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
					elif [[ "${ANSWER}" == 3 ]]; then
						if [[ "${PLATFORM}" == macOS ]]; then
							showNotSupportedCommand
						else
							addTitleBar "List of URL"
							clear
							showLines "*"
							showTitleBar
							showLines "-"
							echo "https://mesu.apple.com/assets"
							echo "https://mesu.apple.com/assets/watch"
							echo "http://mesu.apple.com/assets/tv"
							echo "http://mesu.apple.com/assets/audio"
							echo "https://mesu.apple.com/assets/iOS11DeveloperSeed"
							showLines "*"
							showPA2C
							backTitleBar
						fi
					else
						replyAnswer
					fi
				done
			fi
		elif [[ "${ANSWER}" == 6 ]]; then
			if [[ "${PLATFORM}" == macOS ]]; then
				showNotSupportedCommand
			else
				readAnswer "INTERNAL_BUILD_NAME=" INTERNAL_BUILD_NAME
			fi
		elif [[ "${ANSWER}" == 7 ]]; then
			if [[ ! "${PLATFORM}" == macOS && ! "${PARSE_DOCUMENTATION_ONLY}" == YES ]]; then
				readAnswer "PREREQUISITE_VERISON=" PREREQUISITE_VERISON
			else
				showNotSupportedCommand
			fi
		elif [[ "${ANSWER}" == 8 ]]; then
			if [[ ! "${PLATFORM}" == macOS && ! "${PARSE_DOCUMENTATION_ONLY}" == YES ]]; then
				readAnswer "PREREQUISITE_BUILD=" PREREQUISITE_BUILD
			else
				showNotSupportedCommand
			fi
		elif [[ "${ANSWER}" == reset || "${ANSWER}" == r ]]; then
			resetValues
		elif [[ "${ANSWER}" == start || "${ANSWER}" == s ]]; then
			if [[ -z "${PLATFORM}" ]]; then
				showError "Fill Platform."
				HAS_ERROR=YES
			fi
			if [[ -z "${CATALOG}" ]]; then
				if [[ ! "${PLATFORM}" == watchOS || ! "${PARSE_DOCUMENTATION_ONLY}" == YES ]]; then
					showError "Fill Catalog."
					HAS_ERROR=YES
				fi
			fi
			if [[ "${HAS_ERROR}" == YES ]]; then
				HAS_ERROR=NO
				showPA2C
			else
				break
			fi
		else
			replyAnswer
		fi
	done
}

function detectCatalog(){
	CATALOG=
	if [[ "${PLATFORM}" == macOS ]]; then
		CURRENT_ENROLLED_SEED=$(${SEEDUTIL_COMMAND} current | grep "Currently enrolled in" | cut -d" " -f4)
		echo "Currently enrolled in: ${CURRENT_ENROLLED_SEED}"
		if [[ "${CURRENT_ENROLLED_SEED}" == "(null)" ]]; then
			"${SEEDUTIL_COMMAND}" enroll DeveloperSeed > /dev/null 2>&1
		fi
		CATALOG=$(${SEEDUTIL_COMMAND} current | grep CatalogURL | cut -d" " -f2)
		echo "CatalogURL: ${CATALOG}"
		if [[ "${CURRENT_ENROLLED_SEED}" == "(null)" ]]; then
			"${SEEDUTIL_COMMAND}" unenroll > /dev/null 2>&1
		fi
		showPA2C
	else
		readAnswer "Path of .mobileconfig: " PATH_MOBILECONFIG
		if [[ -z "${PATH_MOBILECONFIG}" ]]; then
			:
		elif [[ ! -f "${PATH_MOBILECONFIG}" ]]; then
			showError "No such file: ${PATH_MOBILECONFIG}"
		elif [[ -d "${PATH_MOBILECONFIG}" ]]; then
			showError "${PATH_MOBILECONFIG} is directory."
		else
			VALUE=
			PASS_ONCE_1=No
			for VALUE in $(strings "${PATH_MOBILECONFIG}"); do
				if [[ "${VALUE}" == "<key>MobileAssetServerURL-com.apple.MobileAsset.SoftwareUpdate</key>" ]]; then
					PASS_ONCE_1=YES
				elif [[ "${PASS_ONCE_1}" == YES ]]; then
					CATALOG="$(echo "${VALUE}" | cut -d">" -f2 | cut -d"<" -f1)"
					PASS_ONCE_1=NO
					break
				fi
			done
		fi
	fi
}

function resetValues(){
	PLATFORM=
	DEVICE=
	VERSION=
	BUILD=
	CATALOG=
	INTERNAL_BUILD_NAME=
	PREREQUISITE_VERISON=
	PREREQUISITE_BUILD=
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
	if [[ "${ANSWER}" == back || "${ANSWER}" == b || "${ANSWER}" == q ]]; then
		if [[ "$(showTitleBar)" == Home ]]; then
			showNotSupportedCommand
		else
			backTitleBar
			break
		fi
	elif [[ "${ANSWER}" == exit || "${ANSWER}" == e ]]; then
		quitTool 0
	elif [[ "${ANSWER}" == adv || "${ANSWER}" == a ]]; then
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
		echo "(6) Set Profile"
		echo "(7) Set Color Scheme"
		echo "(8) Remove Color Scheme"
		if [[ "${PARSE_DOCUMENTATION_ONLY}" == YES ]]; then
			echo "(9) Parse documentation only : ${BLUE}${PARSE_DOCUMENTATION_ONLY}${NC}"
		else
			echo "(9) Parse documentation only : ${BLUE}NO${NC}"
		fi
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
			"${SEEDUTIL_COMMAND}" enroll DeveloperSeed
			showPA2C
		elif [[ "${ANSWER}" == 4 ]]; then
			"${SEEDUTIL_COMMAND}" enroll PublicSeed
			showPA2C
		elif [[ "${ANSWER}" == 5 ]]; then
			"${SEEDUTIL_COMMAND}" unenroll
			showPA2C
		elif [[ "${ANSWER}" == 6 ]]; then
			addTitleBar "Set Profile"
			while(true); do
				clear
				showLines "*"
				showTitleBar
				showLines "-"
				echo "(1) macOS 1"
				echo "(2) iOS 1"
				showLines "*"
				readAnswer
				if [[ "${ANSWER}" == 1 ]]; then
					resetValues
					PLATFORM=macOS
					CATALOG=https://swscan.apple.com/content/catalogs/others/index-10.13seed-10.13-10.12-10.11-10.10-10.9-mountainlion-lion-snowleopard-leopard.merged-1.sucatalog.gz
					VERSION=10.13.4
					BUILD=17E139j
					backTitleBar
					break
				elif [[ "${ANSWER}" == 2 ]]; then
					resetValues
					PLATFORM=etc
					CATALOG=https://mesu.apple.com/assets/iOS11DeveloperSeed
					VERSION=11.3
					backTitleBar
					break
				else
					replyAnswer
				fi
			done
		elif [[ "${ANSWER}" == 7 ]]; then
			setColorScheme
		elif [[ "${ANSWER}" == 8 ]]; then
			BLUE=
			RED=
		elif [[ "${ANSWER}" == 9 ]]; then
			if [[ "${PARSE_DOCUMENTATION_ONLY}" == YES ]]; then
				PARSE_DOCUMENTATION_ONLY=NO
			else
				PARSE_DOCUMENTATION_ONLY=YES
			fi
		else
			replyAnswer
		fi
	done
}

function showError(){
	if [[ -z "${1}" ]]; then
		echo "${RED}ERROR!${NC}"
	else
		echo "${RED}ERROR: ${1}${NC}"
	fi
}

function showNotSupportedCommand(){
	echo "${RED}Not supported command: ${ANSWER}${NC}"
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

function downloadAssets(){
	deleteFile "${PROJECT_DIR}/assets.gz"
	deleteFile "${PROJECT_DIR}/assets"
	deleteFile "${PROJECT_DIR}/assets.xml"
	if [[ "${PLATFORM}" == macOS ]]; then
		curl -# -o "${PROJECT_DIR}/assets.gz" "${CATALOG}"
		gunzip "${PROJECT_DIR}/assets.gz"
		if [[ ! -f  "${PROJECT_DIR}/assets" ]]; then
			showError "Failed to get assets."
			quitTool 1
		fi
		mv "${PROJECT_DIR}/assets" "${PROJECT_DIR}/assets.xml"
	else
		curl -# -o "${PROJECT_DIR}/assets.xml" "${CATALOG}/com_apple_MobileAsset_SoftwareUpdate/com_apple_MobileAsset_SoftwareUpdate.xml"
		if [[ ! -f "${PROJECT_DIR}/assets.xml" ]]; then
			showError "Failed to get assets."
			quitTool 1
		fi
	fi
}

function downloadDocumentation(){
	deleteFile "${PROJECT_DIR}/documentation.xml"
	if [[ "${PLATFORM}" == watchOS ]]; then
		curl -# -o "${PROJECT_DIR}/documentation.xml" "https://mesu.apple.com/assets/com_apple_MobileAsset_WatchSoftwareUpdateDocumentation/com_apple_MobileAsset_WatchSoftwareUpdateDocumentation.xml"
	else
		curl -# -o "${PROJECT_DIR}/documentation.xml" "${CATALOG}/com_apple_MobileAsset_SoftwareUpdateDocumentation/com_apple_MobileAsset_SoftwareUpdateDocumentation.xml"
	fi
	if [[ ! -f "${PROJECT_DIR}/documentation.xml" ]]; then
		showError "Failed to get documentation."
		quitTool 1
	fi
}

function parseAssets(){
	startOverParseStage
	VALUE=
	if [[ "${PLATFORM}" == macOS ]]; then
		PASS_ONCE_1=YES
		for VALUE in $(cat "${PROJECT_DIR}/assets.xml"); do
			if [[ ! "${START_RECORDING}" == YES ]]; then
				if [[ "${PASS_ONCE_1}" == YES ]]; then
					SUB_VALUE_1="${VALUE}"
					PASS_ONCE_1=NO
					PASS_ONCE_2=YES
					if [[ "${SUB_VALUE_1}" == "<key>ServerMetadataURL</key>" ]]; then
						UPDATE_KEY="$(echo "${SUB_VALUE_2}" | cut -d">" -f2 | cut -d"<" -f1)"
						START_RECORDING=YES
					fi
				elif [[ "${PASS_ONCE_2}" == YES ]]; then
					SUB_VALUE_2="${VALUE}"
					PASS_ONCE_2=NO
					PASS_ONCE_3=YES
					if [[ "${SUB_VALUE_2}" == "<key>ServerMetadataURL</key>" ]]; then
						UPDATE_KEY="$(echo "${SUB_VALUE_3}" | cut -d">" -f2 | cut -d"<" -f1)"
						START_RECORDING=YES
					fi
				elif [[ "${PASS_ONCE_3}" == YES ]]; then
					SUB_VALUE_3="${VALUE}"
					PASS_ONCE_3=NO
					PASS_ONCE_1=YES
					if [[ "${SUB_VALUE_3}" == "<key>ServerMetadataURL</key>" ]]; then
						UPDATE_KEY="$(echo "${SUB_VALUE_1}" | cut -d">" -f2 | cut -d"<" -f1)"
						START_RECORDING=YES
					fi
				fi
			fi
			if [[ "${START_RECORDING}" == YES ]]; then
				echo "${VALUE}" >> "${PROJECT_DIR}/data/${UPDATE_KEY}.txt"
				if [[ ! -z "${VERSION}" ]]; then
					if [[ "${VALUE}" == "<key>ProductVersion</key>" ]]; then
						PASS_ONCE_4=YES
					elif [[ "${PASS_ONCE_4}" == YES ]]; then
						PASS_ONCE_4=NO
						SEARCHED_VERSION=YES
						if [[ ! "<string>${VERSION}</string>" == "${VALUE}" ]]; then
							startOverParseStage
						fi
					fi
				fi
				if [[ ! -z "${BUILD}" || ! -z "${DEVICE}" ]]; then
					if [[ "${VALUE}" == "<key>English</key>" ]]; then
						if [[ ! -z "${VERSION}" && ! "${SEARCHED_VERSION}" == YES ]]; then
							startOverParseStage
						else
							PASS_ONCE_5=YES
						fi
					elif [[ "${PASS_ONCE_5}" == YES ]]; then
						PASS_ONCE_5=NO
						deleteFile "${PROJECT_DIR}/English.dist"
						echo "${UPDATE_KEY}"
						curl -# -o "${PROJECT_DIR}/English.dist" "$(echo "${VALUE}" | cut -d">" -f2 | cut -d"<" -f1)"
						if [[ -f "${PROJECT_DIR}/English.dist" ]]; then
							if [[ ! -z "${BUILD}" ]]; then
								SUB_VALUE_4="${VALUE}"
								for VALUE in $(cat "${PROJECT_DIR}/English.dist"); do
									if [[ "${VALUE}" == "<key>macOSProductBuildVersion</key>" ]]; then
										PASS_ONCE_6=YES
									elif [[ "${PASS_ONCE_6}" == YES ]]; then
										PASS_ONCE_6=NO
										if [[ "<string>${BUILD}</string>" == "${VALUE}" ]]; then
											SEARCHED_BUILD=YES
										else
											startOverParseStage
										fi
										break
									fi
								done
								VALUE="${SUB_VALUE_4}"
							fi
							if [[ ! -z "${DEVICE}" && ! -z "$(cat "${PROJECT_DIR}/English.dist" | grep "nonSupportedModels" | grep "${DEVICE}")" ]]; then
								startOverParseStage
							fi
							deleteFile "${PROJECT_DIR}/English.dist"
						else
							showError "Failed to get ${UPDATE_KEY} Distributions."
							startOverParseStage
						fi
					fi
				fi
				if [[ "${VALUE}" == "<key>English</key>" ]]; then
					PASS_ONCE_7=YES
				elif [[ "${PASS_ONCE_7}" == YES ]]; then
					PASS_ONCE_7=NO
					PASS_ONCE_8=YES
				elif [[ "${PASS_ONCE_8}" == YES ]]; then
					PASS_ONCE_8=NO
					if [[ "${VALUE}" == "</dict>" ]]; then
						if [[ ! -z "${VERSION}" && ! "${SEARCHED_VERSION}" == YES ]]; then
							startOverParseStage
						fi
						if [[ ! -z "${VERSION}" && ! "${SEARCHED_VERSION}" == YES ]]; then
							startOverParseStage
						fi
						startOverParseStage --no-reset
					else
						PASS_ONCE_7=YES
					fi
				fi
			fi
		done
	else
		for VALUE in $(cat "${PROJECT_DIR}/assets.xml"); do
			if [[ "${VALUE}" == "<key>ActualMinimumSystemPartition</key>" ]]; then
				START_RECORDING=YES
			fi
			if [[ "${START_RECORDING}" == YES ]]; then
				echo "${VALUE}" >> "${PROJECT_DIR}/data/untitled.txt"
				if [[ "${VALUE}" == "<key>Build</key>" ]]; then
					PASS_ONCE_1=YES
				elif [[ "${PASS_ONCE_1}" == YES ]]; then
					PASS_ONCE_1=NO
					NAME_BUILD="${VALUE}"
					if [[ ! -z "${BUILD}" && ! "<string>${BUILD}</string>" == "${NAME_BUILD}" ]]; then
						startOverParseStage
					fi
				fi
				if [[ "${VALUE}" == "<key>OSVersion</key>" ]]; then
					PASS_ONCE_2=YES
				elif [[ "${PASS_ONCE_2}" == YES ]]; then
					PASS_ONCE_2=NO
					NAME_OSVERSION="${VALUE}"
					if [[ ! -z "${VERSION}" && ! "<string>${VERSION}</string>" == "${NAME_OSVERSION}" && ! "<string>9.9.${VERSION}</string>" == "${NAME_OSVERSION}" ]]; then
						startOverParseStage
					fi
				fi
				if [[ "${VALUE}" == "<key>PrerequisiteBuild</key>" ]]; then
					PASS_ONCE_3=YES
				elif [[ "${PASS_ONCE_3}" == YES ]]; then
					PASS_ONCE_3=NO
					SEARCHED_PREREQUISITE=YES
					NAME_PREREQUISITE_BUILD="${VALUE}"
					if [[ ! -z "${PREREQUISITE_BUILD}" && ! "<string>${PREREQUISITE_BUILD}</string>" == "${VALUE}" ]]; then
						startOverParseStage
					fi
				fi
				if [[ "${VALUE}" == "<key>PrerequisiteOSVersion</key>" ]]; then
					PASS_ONCE_4=YES
				elif [[ "${PASS_ONCE_4}" == YES ]]; then
					PASS_ONCE_4=NO
					SEARCHED_PREREQUISITE=YES
					NAME_PREREQUISITE_VERSION="${VALUE}"
					if [[ ! -z "${PREREQUISITE_VERISON}" && ! "<string>${PREREQUISITE_VERISON}</string>" == "${VALUE}" ]]; then
						startOverParseStage
					fi
				fi
				if [[ "${VALUE}" == "<key>SUDocumentationID</key>" ]]; then
					PASS_ONCE_5=YES
				elif [[ "${PASS_ONCE_5}" == YES ]]; then
					PASS_ONCE_5=NO
					NAME_INTERNAL_BUILD="${VALUE}"
					if [[ ! -z "${INTERNAL_BUILD_NAME}" && ! "<string>${INTERNAL_BUILD_NAME}</string>" == "${VALUE}" ]]; then
						startOverParseStage
					fi
				fi
				if [[ "${VALUE}" == "<key>SupportedDeviceModels</key>" ]]; then
					PASS_ONCE_6=YES
				elif [[ "${PASS_ONCE_6}" == YES ]]; then
					PASS_ONCE_6=NO
					PASS_ONCE_7=YES
				elif [[ "${PASS_ONCE_7}" == YES ]]; then
					PASS_ONCE_7=NO
					NAME_CODE_DEVICE="${VALUE}"
					if [[ ! -z "${DEVICE}" && ! "<string>${DEVICE}</string>" == "${NAME_CODE_DEVICE}" ]]; then
						PASS_ONCE_8=YES
					fi
				fi
				if [[ "${VALUE}" == "<key>SupportedDevices</key>" ]]; then
					PASS_ONCE_9=YES
				elif [[ "${PASS_ONCE_9}" == YES ]]; then
					PASS_ONCE_9=NO
					PASS_ONCE_10=YES
				elif [[ "${PASS_ONCE_10}" == YES ]]; then
					PASS_ONCE_10=NO
					NAME_DEVICE="${VALUE}"
					if [[ "${PASS_ONCE_8}" == YES && ! -z "${DEVICE}" && ! "<string>${DEVICE}</string>" == "${NAME_DEVICE}" ]]; then
						startOverParseStage
					fi
				fi
				if [[ "${VALUE}" == "<key>__RelativePath</key>" ]]; then
					PASS_ONCE_11=YES
				elif [[ "${PASS_ONCE_11}" == YES ]]; then
					PASS_ONCE_11=NO
					cutName
					if [[ "${SEARCHED_PREREQUISITE}" == YES ]]; then
						deleteFile "${PROJECT_DIR}/data/${NAME_CODE_DEVICE}_${NAME_DEVICE}_${NAME_OSVERSION}_${NAME_BUILD}_${NAME_INTERNAL_BUILD}_Prerequisite_${NAME_PREREQUISITE_VERSION}_${NAME_PREREQUISITE_BUILD}.txt"
						mv "${PROJECT_DIR}/data/untitled.txt" "${PROJECT_DIR}/data/${NAME_CODE_DEVICE}_${NAME_DEVICE}_${NAME_OSVERSION}_${NAME_BUILD}_${NAME_INTERNAL_BUILD}_Prerequisite_${NAME_PREREQUISITE_VERSION}_${NAME_PREREQUISITE_BUILD}.txt"
					else
						if [[ -z "${PREREQUISITE_BUILD}" && -z "${PREREQUISITE_VERISON}" ]]; then
							deleteFile "${PROJECT_DIR}/data/${NAME_CODE_DEVICE}_${NAME_DEVICE}_${NAME_OSVERSION}_${NAME_BUILD}_${NAME_INTERNAL_BUILD}.txt"
							mv "${PROJECT_DIR}/data/untitled.txt" "${PROJECT_DIR}/data/${NAME_CODE_DEVICE}_${NAME_DEVICE}_${NAME_OSVERSION}_${NAME_BUILD}_${NAME_INTERNAL_BUILD}.txt"
						fi
					fi
					startOverParseStage
				fi
			fi
		done
	fi		
}

function parseDocumentation(){
	startOverParseStage
	VALUE=
	for VALUE in $(cat "${PROJECT_DIR}/documentation.xml"); do
		if [[ "${VALUE}" == "<key>Device</key>" ]]; then
			START_RECORDING=YES
		fi
		if [[ "${START_RECORDING}" == YES ]]; then
			echo "${VALUE}" >> "${PROJECT_DIR}/data/untitled.txt"
			if [[ "${VALUE}" == "<key>Device</key>" ]]; then
				PASS_ONCE_1=YES
			elif [[ "${PASS_ONCE_1}" == YES ]]; then
				PASS_ONCE_1=NO
				NAME_DEVICE="${VALUE}"
				if [[ ! -z "${DEVICE}" && -z "$(echo "${DEVICE}" | grep "$(echo "${VALUE}" | cut -d">" -f2 | cut -d"<" -f1)")" ]]; then
					startOverParseStage
				fi
			fi
			if [[ "${VALUE}" == "<key>OSVersion</key>" ]]; then
				PASS_ONCE_2=YES
			elif [[ "${PASS_ONCE_2}" == YES ]]; then
				PASS_ONCE_2=NO
				NAME_OSVERSION="${VALUE}"
				if [[ ! -z "${VERSION}" && ! "<string>${VERSION}</string>" == "${VALUE}" ]]; then
					startOverParseStage
				fi
			fi
			if [[ "${VALUE}" == "<key>SUDocumentationID</key>" ]]; then
				PASS_ONCE_3=YES
			elif [[ "${PASS_ONCE_3}" == YES ]]; then
				PASS_ONCE_3=NO
				NAME_INTERNAL_BUILD="${VALUE}"
				if [[ ! -z "${INTERNAL_BUILD_NAME}" && ! "<string>${INTERNAL_BUILD_NAME}</string>" == "${VALUE}" ]]; then
					startOverParseStage
				fi
			fi
			if [[ "${VALUE}" == "<key>__RelativePath</key>" ]]; then
				PASS_ONCE_4=YES
			elif [[ "${PASS_ONCE_4}" == YES ]]; then
				cutName
				deleteFile "${PROJECT_DIR}/data/documentation_${NAME_DEVICE}_${NAME_OSVERSION}_${NAME_INTERNAL_BUILD}.txt"
				mv "${PROJECT_DIR}/data/untitled.txt" "${PROJECT_DIR}/data/documentation_${NAME_DEVICE}_${NAME_OSVERSION}_${NAME_INTERNAL_BUILD}.txt"
				startOverParseStage
			fi
		fi
	done
}

function startOverParseStage(){
	SUB_VALUE_1=NO
	SUB_VALUE_2=NO
	SUB_VALUE_3=NO
	SUB_VALUE_4=NO
	PASS_ONCE_1=NO
	PASS_ONCE_2=NO
	PASS_ONCE_3=NO
	PASS_ONCE_4=NO
	PASS_ONCE_5=NO
	PASS_ONCE_6=NO
	PASS_ONCE_7=NO
	PASS_ONCE_8=NO
	PASS_ONCE_9=NO
	PASS_ONCE_10=NO
	PASS_ONCE_11=NO
	if [[ "${PLATFORM}" == macOS ]]; then
		if [[ ! "${1}" == "--no-reset" && ! -z "${UPDATE_KEY}" ]]; then
			deleteFile "${PROJECT_DIR}/data/${UPDATE_KEY}.txt"
		fi
		PASS_ONCE_1=YES
	fi
	deleteFile "${PROJECT_DIR}/data/untitled.txt"
	deleteFile "${PROJECT_DIR}/English.dist"
	START_RECORDING=NO
	UPDATE_KEY=
	NAME_BUILD=
	NAME_OSVERSION=
	NAME_PREREQUISITE_BUILD=
	NAME_PREREQUISITE_VERSION=
	NAME_INTERNAL_BUILD=
	NAME_CODE_DEVICE=
	NAME_DEVICE=
	SEARCHED_VERSION=NO
	SEARCHED_VERSION=NO
	SEARCHED_PREREQUISITE=NO
}

function cutName(){
	NAME_BUILD="$(echo "${NAME_BUILD}" | cut -d">" -f2 | cut -d"<" -f1)"
	NAME_OSVERSION="$(echo "${NAME_OSVERSION}" | cut -d">" -f2 | cut -d"<" -f1)"
	NAME_PREREQUISITE_BUILD="$(echo "${NAME_PREREQUISITE_BUILD}" | cut -d">" -f2 | cut -d"<" -f1)"
	NAME_PREREQUISITE_VERSION="$(echo "${NAME_PREREQUISITE_VERSION}" | cut -d">" -f2 | cut -d"<" -f1)"
	NAME_INTERNAL_BUILD="$(echo "${NAME_INTERNAL_BUILD}" | cut -d">" -f2 | cut -d"<" -f1)"
	NAME_CODE_DEVICE="$(echo "${NAME_CODE_DEVICE}" | cut -d">" -f2 | cut -d"<" -f1)"
	NAME_DEVICE="$(echo "${NAME_DEVICE}" | cut -d">" -f2 | cut -d"<" -f1)"
}

function setColorScheme(){
	BLUE="\033[1;36m"
	RED="\033[1;31m"
	NC="\033[0m"
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
	#deleteFile "${PROJECT_DIR}"
	exit "${1}"
}

setDefaultSettings
setProjectPath
setColorScheme
showInferface
if [[ ! "${PARSE_DOCUMENTATION_ONLY}" == YES ]]; then
	downloadAssets
	parseAssets
fi
if [[ -z "$(ls "${PROJECT_DIR}/data")" && ! "${PARSE_DOCUMENTATION_ONLY}" == YES ]]; then
	showError "No data found."
	quitTool 1
else
	if [[ "${PLATFORM}" == macOS ]]; then
		echo "Location of data : ${PROJECT_DIR}/data"
		open "${PROJECT_DIR}/data"
		quitTool 0
	else
		downloadDocumentation
		parseDocumentation
		if [[ -z "$(ls "${PROJECT_DIR}/data")" ]]; then
			showError "No data found."
			quitTool 1
		else
			echo "Location of data : ${PROJECT_DIR}/data"
			open "${PROJECT_DIR}/data"
			quitTool 0
		fi
	fi
fi
