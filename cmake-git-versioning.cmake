# ---- INFO ---- #

# Copyright (C) 2022 Giuseppe Emanuele Messina - https://github.com/emanuelemessina
# This code is licensed under the MIT License (see https://github.com/emanuelemessina/cmake-git-versioning/blob/master/LICENSE)

# This module is strongly inspired by the public domain https://github.com/nunofachada/cmake-git-semver. Original author: Nuno Fachada

###########################################################################

# ---- DOCUMENTATION ---- #

# See https://github.com/emanuelemessina/cmake-git-versioning/blob/master/README.md

###########################################################################



if (GIT_FOUND) # check git presence

	# try to get last tag from git and set VERSION_STRING to it
	execute_process(COMMAND ${GIT_EXECUTABLE} describe --abbrev=0 --tags
		WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
		OUTPUT_VARIABLE PROJECT_VERSION_STRING
		OUTPUT_STRIP_TRAILING_WHITESPACE
		RESULT_VARIABLE STATUS
		)

	# check if the last tag actually was retrieved
	
	if(STATUS AND NOT STATUS EQUAL 0) # no tag found, check the version file
	
		message(STATUS "No git tags found, checking for a .version file...")
		unset(GIT_TAG_FOUND)
	
	else() # a tag was found

		# try to parse the tag into two match alternatives, the second alternative is the tweak
		string(REGEX MATCHALL "[0-9]+|-(.*).([0-9]+)$" PROJECT_PARTIAL_VERSION_LIST ${PROJECT_VERSION_STRING})

		list(LENGTH PROJECT_PARTIAL_VERSION_LIST PROJECT_PARTIAL_VERSION_LIST_LEN)

		if(PROJECT_PARTIAL_VERSION_LIST_LEN LESS 3) # does not math the mandatory MMP pattern

			message(STATUS "Couldn't read any version number from the last tag. Checking cached .version file...")
			unset(GIT_TAG_FOUND)
		
		else()

			# set the mandatory version numbers
			list(GET PROJECT_PARTIAL_VERSION_LIST
			0 PROJECT_VERSION_MAJOR)
			list(GET PROJECT_PARTIAL_VERSION_LIST
				1 PROJECT_VERSION_MINOR)
			list(GET PROJECT_PARTIAL_VERSION_LIST
				2 PROJECT_VERSION_PATCH)

			message(STATUS "Retrieved git version tag: ${PROJECT_VERSION_STRING}")
			set(GIT_TAG_FOUND TRUE)

		endif()

	endif()

endif()



if(GIT_TAG_FOUND) # parse the rest of the tag

	unset(GIT_TAG_FOUND)



	# check if tweak match is present

	if (PROJECT_PARTIAL_VERSION_LIST_LEN GREATER 3) # there is a third match, check syntax

		# eg. -alpha.2
		# if the tweak does not match the syntax the matches will be null and it will default to 0.0

		# tweak string : alpha
		if(${CMAKE_MATCH_1})
			set(PROJECT_VERSION_TWEAK_NAME ${CMAKE_MATCH_1})
		else()
			set(PROJECT_VERSION_TWEAK_NAME 0)
		endif()
		
		# tweak number : 2
		if(${CMAKE_MATCH_2})
			set(PROJECT_VERSION_TWEAK_NUMBER ${CMAKE_MATCH_2})
		else()
			set(PROJECT_VERSION_TWEAK_NUMBER 0)
		endif()

	else() # no third match, default

		set(PROJECT_VERSION_TWEAK_NAME 0)
		set(PROJECT_VERSION_TWEAK_NUMBER 0)

	endif()

	unset(PROJECT_PARTIAL_VERSION_LIST)


	# get commit metadata

	# get num commits since last tag
	execute_process(COMMAND ${GIT_EXECUTABLE} rev-list ${PROJECT_VERSION_STRING}^..HEAD --count
		WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
		OUTPUT_VARIABLE PROJECT_VERSION_COMMITS_AHEAD
		OUTPUT_STRIP_TRAILING_WHITESPACE)

	# get current commit SHA
	execute_process(COMMAND ${GIT_EXECUTABLE} rev-parse --short HEAD
		WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
		OUTPUT_VARIABLE PROJECT_VERSION_COMMIT_SHA
		OUTPUT_STRIP_TRAILING_WHITESPACE)

	# Build VERSION_STRING_FULL from VERSION_STRING and git metadata
	set(PROJECT_VERSION_STRING_FULL
		${PROJECT_VERSION_STRING}+${PROJECT_VERSION_COMMITS_AHEAD}.${PROJECT_VERSION_COMMIT_SHA})



	# Cache version full string as well as the single parts into .version file
	file(WRITE ${CMAKE_SOURCE_DIR}/.version ${PROJECT_VERSION_STRING_FULL}
		"*" ${PROJECT_VERSION_STRING}
		"*" ${PROJECT_VERSION_MAJOR}
		"*" ${PROJECT_VERSION_MINOR}
		"*" ${PROJECT_VERSION_PATCH}
		"*" ${PROJECT_VERSION_TWEAK_NAME}
		"*" ${PROJECT_VERSION_TWEAK_NUMBER}
		"*" ${PROJECT_VERSION_COMMITS_AHEAD}
		"*" ${PROJECT_VERSION_COMMIT_SHA})



else() # not git version tag found, check .version file

	if( EXISTS ${CMAKE_SOURCE_DIR}/.version )

		message("Found cached .version file, extracting info...")

		file(STRINGS ${CMAKE_SOURCE_DIR}/.version VERSION_FILE_LIST)
		# match replace out in
		string(REPLACE "*" ";" VERSION_FILE_LIST ${VERSION_FILE_LIST})

		# check that the list is valid

		unset(VALID_VERSION_FILE)
		
		list(LENGTH VERSION_FILE_LIST VERSION_FILE_LIST_LEN)

		if(${VERSION_FILE_LIST_LEN} EQUAL 9)
		
			# set partial variables
			list(GET VERSION_FILE_LIST 0 PROJECT_VERSION_STRING_FULL)
			list(GET VERSION_FILE_LIST 1 PROJECT_VERSION_STRING)
			list(GET VERSION_FILE_LIST 2 PROJECT_VERSION_MAJOR)
			list(GET VERSION_FILE_LIST 3 PROJECT_VERSION_MINOR)
			list(GET VERSION_FILE_LIST 4 PROJECT_VERSION_PATCH)
			list(GET VERSION_FILE_LIST 5 PROJECT_VERSION_TWEAK_NAME)
			list(GET VERSION_FILE_LIST 6 PROJECT_VERSION_TWEAK_NUMBER)
			list(GET VERSION_FILE_LIST 7 PROJECT_VERSION_COMMITS_AHEAD)
			list(GET VERSION_FILE_LIST 8 PROJECT_VERSION_COMMIT_SHA)

			# check strings validity
			if( 
				NOT	PROJECT_VERSION_STRING_FULL STREQUAL ""
			AND NOT PROJECT_VERSION_STRING STREQUAL ""
			AND NOT PROJECT_VERSION_TWEAK_NAME STREQUAL ""
			AND NOT PROJECT_VERSION_COMMIT_SHA STREQUAL ""
			)
				# check numbers validity
				if(
					PROJECT_VERSION_MAJOR MATCHES "^[0-9]+$"
					AND PROJECT_VERSION_MINOR MATCHES "^[0-9]+$"
					AND PROJECT_VERSION_PATCH MATCHES "^[0-9]+$"
					AND PROJECT_VERSION_TWEAK_NUMBER MATCHES "^[0-9]+$"
					AND PROJECT_VERSION_COMMITS_AHEAD MATCHES "^[0-9]+$"
				)
					set(VALID_VERSION_FILE TRUE)
				endif() # file corrupt

			endif() # file corrupt

		endif() # file corrupt

		unset(VERSION_FILE_LIST)
	
	endif()

	if(NOT DEFINED VALID_VERSION_FILE) # a valid .version file was not found, at least pass a default version to the project

		message(AUTHOR_WARNING "Neither a version tag nor a valid .version file could be found, couldn't retrieve any version number. Defaulting to 1.0.0 .")

		set(PROJECT_VERSION_STRING v1.0.0)
		set(PROJECT_VERSION_STRING_FULL v1.0.0)

		set(PROJECT_VERSION_MAJOR 1)
		set(PROJECT_VERSION_MINOR 0)
		set(PROJECT_VERSION_PATCH 0)

		set(PROJECT_VERSION_TWEAK_NAME 0)
		set(PROJECT_VERSION_TWEAK_NUMBER 0)

		set(PROJECT_VERSION_COMMITS_AHEAD 0)
		set(PROJECT_VERSION_COMMIT_SHA 0)

	endif()

endif()

# at this point it is ensured that all variables are set

unset(VALID_VERSION_FILE)



# assemble the last variables

set(PROJECT_VERSION_MMP ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}.${PROJECT_VERSION_PATCH})

set(PROJECT_VERSION_TWEAK_FULL ${PROJECT_VERSION_TWEAK_NAME}.${PROJECT_VERSION_TWEAK_NUMBER})

set(PROJECT_VERSION ${PROJECT_VERSION_MMP}-${PROJECT_VERSION_TWEAK_FULL})

set(PROJECT_VERSION_CMAKE ${PROJECT_VERSION_MMP}.${PROJECT_VERSION_TWEAK_NUMBER})



# print the variables

message("PROJECT version info:")
message("	Full project version: ${PROJECT_VERSION_STRING_FULL}")
message("	CMake compatible: ${PROJECT_VERSION_CMAKE}")
message("	Major : ${PROJECT_VERSION_MAJOR}")
message("	minor : ${PROJECT_VERSION_MINOR}")
message("	patch : ${PROJECT_VERSION_PATCH}")
message("	tweak name : ${PROJECT_VERSION_TWEAK_NAME}")
message("	tweak number : ${PROJECT_VERSION_TWEAK_NUMBER}")
message("	Commits ahead : ${PROJECT_VERSION_COMMITS_AHEAD}")
message("	Commit SHA : ${PROJECT_VERSION_COMMIT_SHA}")