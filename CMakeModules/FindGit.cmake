#
#  This program source code file is part of KICAD, a free EDA CAD application.
#
#  Copyright (C) 2010 Wayne Stambaugh <stambaughw@verizon.net>
#  Copyright (C) 2015 Kicad Developers, see AUTHORS.txt for contributors.
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
# This CMake script finds the Git version control system executable and
# and fetches the version string to valid that Git was found and executes
# properly.
#
# Usage:
#  find_package( Git )
#
# User definable.
#    Git_EXECUTABLE         Set this to use a version of Git that is not in
#                           current path.  Defaults to git.
#
# Defines:
#    Git_FOUND              Set to TRUE if Git command line client is found
#                           and the git --version command executes properly.
#    Git_VERSION            Result of the git --version command.
#

set( Git_FOUND FALSE )

find_program( Git_EXECUTABLE git
              DOC "Git version control system command line client" )
mark_as_advanced( Git_EXECUTABLE )

if( Git_EXECUTABLE )

    # Git commands should be executed with the C locale, otherwise
    # the message (which are parsed) may be translated causing the regular
    # expressions to fail.
    set( _Git_SAVED_LC_ALL "$ENV{LC_ALL}" )
    set( ENV{LC_ALL} C )

    # Fetch the Git executable version.
    execute_process( COMMAND ${Git_EXECUTABLE} --version
                     OUTPUT_VARIABLE _git_version_output
                     ERROR_VARIABLE _git_version_error
                     RESULT_VARIABLE _git_version_result
                     OUTPUT_STRIP_TRAILING_WHITESPACE )

    if( ${_git_version_result} EQUAL 0 )
        set( Git_FOUND TRUE )
        string( REGEX REPLACE "^[\n]*Git \\(bzr\\) ([0-9.a-z]+).*"
                "\\1" Git_VERSION "${_git_version_output}" )
        message( STATUS "Git version control system version ${Git_VERSION} found." )
    endif( ${_git_version_result} EQUAL 0 )

    # restore the previous LC_ALL
    set( ENV{LC_ALL} ${_Git_SAVED_LC_ALL} )
endif( Git_EXECUTABLE )

if( NOT Git_FOUND )
    if( NOT Git_FIND_QUIETLY )
        message( STATUS "Git version control command line client was not found." )
    else( NOT Git_FIND_QUIETLY )
        if( Git_FIND_REQUIRED )
            message( FATAL_ERROR "Git version control command line client was not found." )
        endif( Git_FIND_REQUIRED )
    endif( NOT Git_FIND_QUIETLY )
endif( NOT Git_FOUND )
