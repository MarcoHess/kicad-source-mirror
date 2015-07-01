#
#  This program source code file is part of KICAD, a free EDA CAD application.
#
#  Copyright (C) 2010 Wayne Stambaugh <stambaughw@verizon.net>
#  Copyright (C) 2010 Kicad Developers, see AUTHORS.txt for contributors.
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License
#  as published by the Free Software Foundation; either version 2
#  of the License, or (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, you may find one here:
#  http://www.gnu.org/licenses/old-licenses/gpl-2.0.html
#  or you may search the http://www.gnu.org website for the version 2 license,
#  or you may write to the Free Software Foundation, Inc.,
#  51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA
#

macro( create_bzr_version_header )
    # Include Bazaar support to automagically create version header file.
    find_package( Bazaar )

    if( Bazaar_FOUND )
        set( _Bazaar_SAVED_LC_ALL "$ENV{LC_ALL}" )
        set( ENV{LC_ALL} C )

        # Get the tree revison
        execute_process( COMMAND
                         ${Bazaar_EXECUTABLE} revno --tree ${PROJECT_SOURCE_DIR}
                         OUTPUT_VARIABLE _bazaar_TREE_DATE
                         OUTPUT_STRIP_TRAILING_WHITESPACE)

        # Get more info about that revision
        execute_process( COMMAND
                         ${Bazaar_EXECUTABLE} log -r${_bazaar_TREE_DATE} ${PROJECT_SOURCE_DIR}
                         OUTPUT_VARIABLE _bazaar_LAST_CHANGE_LOG
                         ERROR_VARIABLE _bazaar_log_error
                         RESULT_VARIABLE _bazaar_log_result
                         OUTPUT_STRIP_TRAILING_WHITESPACE )

        if( NOT ${_bzr_log_result} EQUAL 0 )
            message(STATUS "Using <build_version.h> for version string.")
        else( NOT ${_bzr_log_result} EQUAL 0 )
            string( REGEX REPLACE "^(.*\n)?revno: ([^ \n]+).*"
                    "\\2" Kicad_REPO_REVISION "${_bazaar_LAST_CHANGE_LOG}" )
            string( REGEX REPLACE "^(.*\n)?committer: ([^\n]+).*"
                    "\\2" Kicad_REPO_LAST_CHANGED_AUTHOR "${_bazaar_LAST_CHANGE_LOG}" )
            string( REGEX REPLACE "^(.*\n)?timestamp: [a-zA-Z]+ ([^ \n]+).*"
                    "\\2" Kicad_REPO_LAST_CHANGED_DATE "${_bazaar_LAST_CHANGE_LOG}" )
        endif( NOT ${_bzr_log_result} EQUAL 0 )

        set( ENV{LC_ALL} ${_Bazaar_SAVED_LC_ALL} )
    endif( Bazaar_FOUND )

    # Check to make sure 'bzr log' command did not fail.  Otherwise fallback
    # to version strings defined in "<kicad-src-dir>/include/build_version.h".
    if( Kicad_REPO_LAST_CHANGED_DATE )
        string( REGEX REPLACE "^([0-9]+)\\-([0-9]+)\\-([0-9]+)" "\\1-\\2-\\3"
                _kicad_bzr_date ${Kicad_REPO_LAST_CHANGED_DATE} )
      	set( KICAD_BUILD_VERSION "(${_kicad_bzr_date} BZR ${Kicad_REPO_REVISION})" )

        # Definition to conditionally use date and revision returned from the
        # Bazaar log command instead of hand coded date and revision in
        # "include/build_version.h".  If Bazaar is not found then the date
        # and version information must be manually edited.
        # Directive means bzr build, program version and build version will
        # reflect this.
        add_definitions( -DHAVE_SVN_VERSION )

        # Generate version.h.
        configure_file( ${CMAKE_SOURCE_DIR}/CMakeModules/version.h.cmake
                        ${CMAKE_BINARY_DIR}/version.h)

        message( STATUS "Kicad Bazaar build version: ${KICAD_BUILD_VERSION}")

    else(Kicad_REPO_LAST_CHANGED_DATE)

        # No version information found from BZR.

        message( STATUS "Not a Bazaar repository. Trying Git.")

        # Check to see if this is a Git repository and try to extract version
        # information from that.
        find_package( Git )

        if( Git_FOUND )

            # Git is a available. See if the source directorty is a Git repository.
            execute_process( COMMAND
                             ${Git_EXECUTABLE} describe --first-parent --always --dirty
                             WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
                             ERROR_VARIABLE  _git_repository_error
                             OUTPUT_VARIABLE _git_INFO
                             OUTPUT_STRIP_TRAILING_WHITESPACE)

            if( "${_git_repository_error}" STREQUAL "" )

                message( STATUS "Git commit '${_git_INFO}'" )

                execute_process( COMMAND
                                 ${Git_EXECUTABLE} symbolic-ref HEAD
                                 WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
                                 OUTPUT_VARIABLE _git_branch
                                 OUTPUT_STRIP_TRAILING_WHITESPACE)

                string( REGEX MATCH "([^\\\\/]*)$" _git_BRANCH ${_git_branch} )

                message(STATUS "Git branch '${_git_BRANCH}'")

                execute_process( COMMAND
                                 ${Git_EXECUTABLE} log --pretty=format:%ci -1
                                 WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
                                 OUTPUT_VARIABLE _git_commit_date
                                 OUTPUT_STRIP_TRAILING_WHITESPACE)

                # Extract just the date portion to have a more compact string. The commit
                # info is really all that is needed so the date is just a feel-good item.
                string( REGEX MATCH "^[0-9\\\\-]*[^\\\\ ]" _git_COMMIT_DATE ${_git_commit_date} )

                message(STATUS "Git commit date '${_git_COMMIT_DATE}'")

                set( KICAD_BUILD_VERSION "(${_git_COMMIT_DATE} GIT ${_git_BRANCH}-${_git_INFO})")

                # Definition to conditionally use date and revision returned from the
                # Git log command instead of hand coded date and revision in
                # "include/build_version.h".  If Git is not found then the date
                # and version information must be manually edited.
                # Directive means either bzr or git program version and build version
                # will reflect this.
                add_definitions( -DHAVE_SVN_VERSION )

                # Generate version.h.
                configure_file( ${CMAKE_SOURCE_DIR}/CMakeModules/version.h.cmake
                                ${CMAKE_BINARY_DIR}/version.h)

                message( STATUS "Kicad Git build version: ${KICAD_BUILD_VERSION}")

            else( "${_git_repository_error}" STREQUAL "" )

                message( STATUS "No Git repository found. Using <build_version.h> for version string." )

            endif( "${_git_repository_error}" STREQUAL "" )

        endif(Git_FOUND)

    endif(Kicad_REPO_LAST_CHANGED_DATE)

endmacro(create_bzr_version_header)
