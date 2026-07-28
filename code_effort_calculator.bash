#!/bin/bash

# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.

# Copyright (c) 2026 Ricardo Cescon - https://cescon.de and/or its affiliates. All rights reserved.

# The contents of this file are subject to the terms of
# Common Development and Distribution License("CDDL") (collectively, the "License").  You
# may not use this file except in compliance with the License.  You can
# obtain a copy of the License at
# https://oss.oracle.com/licenses/CDDL-1.1
# or CDDL-1.1.txt OR LICENSE.txt.  See the License for the specific
# language governing permissions and limitations under the License.

# When distributing the software, include this License Header Notice in each
# file and include the License file at CDDL-1.1.txt OR LICENSE.txt.

# Modifications:
# If applicable, add the following below the License Header, with the fields
# enclosed by brackets [] replaced by your own identifying information:
# "Portions Copyright [year] [name of copyright owner]"

# ══════════════════════════════════════════════════════════════════════
# CONFIGURATION
# ══════════════════════════════════════════════════════════════════════

# Effort History File
EFFORT_HISTORY_FILE="$HOME/.effort_history.csv"

# Per-language LOC/day rates (higher = easier to work with per line)
# Compiled/strict languages get lower rates (harder per line)
# Dynamic/scripting languages get higher rates (faster per line)
# Template/markup languages get highest rates (mostly declarative)
PHP_RATE=500
JS_RATE=400
TS_RATE=380          # TypeScript: stricter than JS, type overhead
TWIG_RATE=800        # Template: declarative
JINJA2_RATE=800      # Template: declarative (like Twig)
JAVA_RATE=450
KOTLIN_RATE=400      # More concise than Java but still JVM complexity
RUST_RATE=300        # Strictest: ownership, lifetimes, borrow checker
GO_RATE=350          # Explicit error handling, no generics complexity
PYTHON_RATE=600      # Concise, dynamic
CSHARP_RATE=450      # Similar to Java
RUBY_RATE=550        # Dynamic, expressive
SWIFT_RATE=380       # Strict typing, protocol-oriented
SCALA_RATE=350       # Functional + OOP complexity
DART_RATE=420        # Flutter/typed, moderate complexity
C_RATE=280           # Manual memory, pointers, low-level
CPP_RATE=300         # C complexity + templates, OOP
SHELL_RATE=500       # Scripting, but brittle
SQL_RATE=600         # Declarative queries
HTML_RATE=1000       # Markup, very declarative
CSS_RATE=900         # Styling, mostly declarative
YAML_RATE=900        # Config, declarative

# Minimum effort floor in days (0.25 = 2 hours)
MIN_EFFORT_DAYS=0.25

# ══════════════════════════════════════════════════════════════════════
# TERMINAL COLORS & FORMATTING
# ══════════════════════════════════════════════════════════════════════

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
BOLD='\033[1m'
DIM='\033[2m'
UNDERLINE='\033[4m'
NC='\033[0m' # No Color

# Box drawing characters
BOX_TL='╔'
BOX_TR='╗'
BOX_BL='╚'
BOX_BR='╝'
BOX_H='═'
BOX_V='║'
BOX_ML='╠'
BOX_MR='╣'
LINE_H='─'
LINE_V='│'
BULLET='●'
ARROW='→'
CHECK='✓'
STAR='★'

# Helper function: print a horizontal rule
hr() {
    local char="${1:-$LINE_H}"
    printf "${GRAY}"
    printf '%0.s'"$char" $(seq 1 60)
    printf "${NC}\n"
}

# Helper function: convert days to "Xh Ym" string
days_to_hm() {
    local days="$1"
    local h m
    h=$(awk "BEGIN {printf \"%d\", int($days * 8)}")
    m=$(awk "BEGIN {printf \"%d\", ($days * 8 - int($days * 8)) * 60}")
    echo "${h}h ${m}m"
}

# Helper function: print a boxed header
box_header() {
    local title="$1"
    local width=58
    echo ""
    printf "  ${CYAN}${BOX_TL}"
    printf '%0.s'"$BOX_H" $(seq 1 "$width")
    printf "${NC}\n"
    printf "  ${CYAN}${BOX_V}${NC} ${BOLD}${WHITE}%s${NC}\n" "$title"
    printf "  ${CYAN}${BOX_BL}"
    printf '%0.s'"$BOX_H" $(seq 1 "$width")
    printf "${NC}\n"
}

# Helper function: print a section header
section_header() {
    local number="$1"
    local title="$2"
    echo ""
    printf "  ${BOLD}${BLUE}[%s]${NC} ${BOLD}%s${NC}\n" "$number" "$title"
    printf "  ${GRAY}"
    printf '%0.s'"$LINE_H" $(seq 1 56)
    printf "${NC}\n"
}

# Function to print usage
print_usage() {
    echo ""
    printf "${BOLD}${CYAN}  Effort Calculator${NC} ${DIM}v3.0${NC}\n"
    echo ""
    printf "  ${BOLD}USAGE:${NC}  $0 [OPTIONS] <file_or_directory> ...\n"
    echo ""
    printf "  ${BOLD}OPTIONS:${NC}\n"
    printf "    ${GREEN}-d, --detailed${NC}    Evaluate each file separately\n"
    printf "    ${GREEN}-p, --preset${NC} ${DIM}KEY=VAL,...${NC}  Non-interactive mode with explicit factors\n"
    printf "    ${GREEN}-h, --help${NC}        Show this help message\n"
    echo ""
    printf "  ${BOLD}PRESET KEYS:${NC}\n"
    printf "    ${DIM}type${NC}        Work type: enhancement, bugfix, version, refactoring\n"
    printf "    ${DIM}complexity${NC}  Level number: 1, 2, 3\n"
    printf "    ${DIM}familiarity${NC} Level: 1=own, 2=team, 3=inherited, 4=unknown\n"
    printf "    ${DIM}testing${NC}     y or n\n"
    printf "    ${DIM}doc${NC}         Level: 1=none, 2=minor, 3=standard, 4=extensive\n"
    printf "    ${DIM}ai${NC}          Level: 1=none, 2=light, 3=moderate, 4=heavy\n"
    echo ""
    printf "  ${BOLD}EXAMPLES:${NC}\n"
    printf "    ${DIM}$0 src/${NC}\n"
    printf "    ${DIM}$0 -d src/Controller/ src/Service/${NC}\n"
    printf "    ${DIM}$0 --preset \"type=version,complexity=2,familiarity=2,testing=y,ai=3\" src/${NC}\n"
    echo ""
    exit 1
}

# Install cloc if missing (run once at startup)
if ! command -v cloc &> /dev/null; then
    echo "Installing cloc..."
    sudo apt install -y cloc
fi

# Parse command line arguments
PARSED_ARGUMENTS=$(getopt -a -n "$0" -o dp:h --long detailed,preset:,help -- "$@")
VALID_ARGUMENTS=$?
if [ "$VALID_ARGUMENTS" != "0" ]; then
    print_usage
fi

eval set -- "$PARSED_ARGUMENTS"
detailed_mode=false
non_interactive=false
preset_string=""

while : ; do
    case "$1" in
        -d | --detailed)
            detailed_mode=true
            shift
            ;;
        -p | --preset)
            preset_string="$2"
            shift 2
            ;;
        -h | --help)
            print_usage
            ;;
        --)
            shift
            break
            ;;
        *)
            print_usage
            ;;
    esac
done

# Parse preset overrides into variables
# Defaults for non-interactive mode
PRESET_TYPE="enhancement"
PRESET_COMPLEXITY=2
PRESET_FAMILIARITY=1
PRESET_TESTING="n"
PRESET_DOC=1
PRESET_AI=1

if [ -n "$preset_string" ]; then
    # Preset implies non-interactive
    non_interactive=true

    IFS=',' read -ra preset_pairs <<< "$preset_string"
    for pair in "${preset_pairs[@]}"; do
        key="${pair%%=*}"
        val="${pair#*=}"
        case "$key" in
            type) PRESET_TYPE="$val" ;;
            complexity) PRESET_COMPLEXITY="$val" ;;
            familiarity) PRESET_FAMILIARITY="$val" ;;
            testing) PRESET_TESTING="$val" ;;
            doc) PRESET_DOC="$val" ;;
            ai) PRESET_AI="$val" ;;
            *)
                printf "  ${RED}Unknown preset key: '%s'${NC}\n" "$key"
                printf "  ${DIM}Valid keys: type, complexity, familiarity, testing, doc, ai${NC}\n"
                exit 1
                ;;
        esac
    done
fi

# Function to get complexity options based on type
# Enhancement: fraction of base effort because you're adding to existing code, not rewriting all of it
# Bugfix: typically touches a small portion of the codebase
# Version Compatibility: scaled by how much of the codebase is affected
# Refactoring: restructuring existing code, not writing from scratch
get_complexity_options() {
    local work_type="$1"
    local output_type="$2"  # 'levels' or 'factors'

    case "$work_type" in
        "Enhancement")
            if [ "$output_type" = "levels" ]; then
                echo "Simple Normal Complex"
            else
                # Realistic: simple change touches ~20% of logic, complex ~60%
                echo "0.2 0.4 0.6"
            fi
            ;;
        "Bugfix")
            if [ "$output_type" = "levels" ]; then
                echo "Trivial Moderate Deep"
            else
                # Bugfixes: trivial is a quick patch, deep requires full understanding
                echo "0.1 0.25 0.5"
            fi
            ;;
        "Version Compatibility")
            if [ "$output_type" = "levels" ]; then
                echo "Minor_(<30%_affected) Major_(30-60%_affected) Full_(>60%_affected)"
            else
                # Version migrations are largely mechanical (API renames, deprecations)
                # Only a fraction of "affected" code requires real cognitive effort
                # Factor reflects that most changes are pattern-based, not creative
                echo "0.3 0.5 0.8"
            fi
            ;;
        "Refactoring")
            if [ "$output_type" = "levels" ]; then
                echo "Simple Normal Complex"
            else
                # Refactoring reuses existing logic; never exceeds writing-from-scratch effort
                # Replaced old 2.5/3.0/3.6 factors which were unrealistically high
                echo "1.0 1.3 1.8"
            fi
            ;;
    esac
}

# Supported file extensions for find commands
FILE_EXTENSIONS='\( -name "*.php" -o -name "*.js" -o -name "*.ts" -o -name "*.twig" -o -name "*.j2" -o -name "*.jinja2" -o -name "*.java" -o -name "*.kt" -o -name "*.rs" -o -name "*.go" -o -name "*.py" -o -name "*.cs" -o -name "*.rb" -o -name "*.swift" -o -name "*.scala" -o -name "*.dart" -o -name "*.c" -o -name "*.h" -o -name "*.cpp" -o -name "*.cc" -o -name "*.hpp" -o -name "*.sh" -o -name "*.bash" -o -name "*.sql" -o -name "*.html" -o -name "*.css" -o -name "*.scss" -o -name "*.yaml" -o -name "*.yml" \)'

# Function to calculate dependency coupling factor
# Counts use/require/import statements to gauge coupling
calculate_coupling_factor() {
    local path="$1"
    local dependency_count=0

    local import_pattern="^(use |require|require_once|include|include_once|import |from .+ import|extern crate|#include|using |open |package )"

    if [ -f "$path" ]; then
        dependency_count=$(grep -cE "$import_pattern" "$path" 2>/dev/null || echo 0)
    elif [ -d "$path" ]; then
        dependency_count=$(eval find "$path" -type f $FILE_EXTENSIONS \
            -exec grep -lE "$import_pattern" {} \; 2>/dev/null \
            | xargs grep -cE "$import_pattern" 2>/dev/null \
            | awk -F: '{sum += $NF} END {print sum+0}')
    fi

    # Sanitise: ensure dependency_count is a clean integer
    dependency_count=$(echo "$dependency_count" | tr -d '[:space:]' | grep -oE '^[0-9]+' || echo 0)
    dependency_count=${dependency_count:-0}

    # Normalise: for directories, use average per file
    if [ -d "$path" ]; then
        local file_count
        file_count=$(eval find "$path" -type f $FILE_EXTENSIONS | wc -l)
        if [ "$file_count" -gt 0 ]; then
            dependency_count=$(echo "scale=0; $dependency_count / $file_count" | bc)
        fi
    fi

    if [ "$dependency_count" -gt 10 ]; then
        echo "1.30"
    elif [ "$dependency_count" -gt 5 ]; then
        echo "1.15"
    else
        echo "1.00"
    fi
}

# Function to calculate git churn factor
# High churn files tend to have more tech debt
calculate_churn_factor() {
    local path="$1"
    local commit_count=0

    # Check if we're in a git repository
    if ! git rev-parse --is-inside-work-tree &>/dev/null; then
        echo "1.00"
        return
    fi

    if [ -f "$path" ]; then
        commit_count=$(git log --oneline -- "$path" 2>/dev/null | wc -l)
    elif [ -d "$path" ]; then
        # Average commits per file in directory
        local total_commits=0
        local file_count=0
        while IFS= read -r -d '' file; do
            local fc
            fc=$(git log --oneline -- "$file" 2>/dev/null | wc -l)
            total_commits=$((total_commits + fc))
            ((file_count++))
        done < <(eval find "$path" -type f $FILE_EXTENSIONS -print0)
        if [ "$file_count" -gt 0 ]; then
            commit_count=$((total_commits / file_count))
        fi
    fi

    if [ "$commit_count" -gt 50 ]; then
        echo "1.20"
    elif [ "$commit_count" -gt 20 ]; then
        echo "1.10"
    else
        echo "1.00"
    fi
}

# Function to calculate graduated template contribution (Twig, Jinja2)
# Graduated weight instead of binary threshold
calculate_template_contribution() {
    local template_loc="$1"

    if [[ -z "$template_loc" || "$template_loc" -eq 0 ]]; then
        echo "0"
        return
    fi

    if [ "$template_loc" -gt 500 ]; then
        # 30% weight for >500 lines
        echo $(echo "scale=0; $template_loc * 30 / 100" | bc)
    elif [ "$template_loc" -gt 100 ]; then
        # 15% weight for 101-500 lines
        echo $(echo "scale=0; $template_loc * 15 / 100" | bc)
    else
        echo "0"
    fi
}

# Function to log effort to history CSV for calibration
log_effort_history() {
    local path="$1"
    local total_loc="$2"
    local selection_type="$3"
    local final_effort="$4"
    local coupling_factor="$5"
    local churn_factor="$6"
    local testing_factor="$7"
    local complexity_factor="$8"
    local base_effort="$9"
    local total_hours="${10}"
    local ai_coding_factor="${11}"
    local ai_level="${12}"
    local ai_overhead_days="${13}"
    local doc_level="${14}"
    local doc_effort_days="${15}"
    local coding_effort="${16}"
    local familiarity_factor="${17}"

    # Create header if file doesn't exist
    if [ ! -f "$EFFORT_HISTORY_FILE" ]; then
        echo "date,timestamp_unix,path,basename,total_weighted_loc,php,js,ts,java,kotlin,rust,go,python,csharp,ruby,swift,scala,dart,c,cpp,shell,sql,twig,jinja2,html,css,yaml,work_type,complexity_factor,familiarity_factor,coupling_factor,churn_factor,testing_factor,ai_coding_factor,ai_level,ai_overhead_days,doc_level,doc_effort_days,base_effort_days,coding_effort_days,estimated_days,estimated_hours,floored" > "$EFFORT_HISTORY_FILE"
    fi

    local basename_path
    basename_path=$(basename "$path")
    local unix_ts
    unix_ts=$(date +%s)
    local floored_flag="no"
    local raw_effort
    raw_effort=$(awk "BEGIN {printf \"%.6f\", ($base_effort * $complexity_factor * $familiarity_factor * $coupling_factor * $churn_factor * $testing_factor * $ai_coding_factor) + $doc_effort_days + $ai_overhead_days}")
    if (( $(awk "BEGIN {print ($final_effort == $MIN_EFFORT_DAYS && $raw_effort < $MIN_EFFORT_DAYS) ? 1 : 0}") )); then
        floored_flag="yes"
    fi

    echo "$(date -Iseconds),$unix_ts,\"$path\",\"$basename_path\",$total_loc,$php_loc,$js_loc,$ts_loc,$java_loc,$kotlin_loc,$rust_loc,$go_loc,$python_loc,$csharp_loc,$ruby_loc,$swift_loc,$scala_loc,$dart_loc,$c_loc,$cpp_loc,$shell_loc,$sql_loc,$twig_loc,$jinja2_loc,$html_loc,$css_loc,$yaml_loc,\"$selection_type\",$complexity_factor,$familiarity_factor,$coupling_factor,$churn_factor,$testing_factor,$ai_coding_factor,\"$ai_level\",$ai_overhead_days,\"$doc_level\",$doc_effort_days,$base_effort,$coding_effort,$final_effort,$total_hours,$floored_flag" >> "$EFFORT_HISTORY_FILE"
}

# Function to calculate effort for a single file
calculate_single_file() {
    local file="$1"
    local filename=$(basename "$file")
    box_header "File: $filename"
    calculate_effort "$file"
    echo ""
}

# Function to process directory/file and calculate effort
calculate_effort() {
    local path="$1"

    # Run cloc and store the output
    local cloc_output
    if [ -f "$path" ]; then
        cloc_output=$(/usr/bin/cloc "$path" 2>/dev/null)
    elif [ -d "$path" ]; then
        cloc_output=$(/usr/bin/cloc "$path" 2>/dev/null)
    else
        echo "Error: '$path' is neither a valid file nor directory"
        exit 1
    fi

    local cloc_exit=$?
    if [ $cloc_exit -ne 0 ]; then
        echo "Error running cloc command. Please check the path."
        exit 1
    fi

    # Extract lines of code using awk
    # cloc outputs language names in its summary table; we match them carefully
    local php_loc=$(echo "$cloc_output" | awk '/^PHP / {print $NF}')
    local js_loc=$(echo "$cloc_output" | awk '/^JavaScript / {print $NF}')
    local ts_loc=$(echo "$cloc_output" | awk '/^TypeScript / {print $NF}')
    local twig_loc=$(echo "$cloc_output" | awk '/^Twig/ {print $NF}')
    local jinja2_loc=$(echo "$cloc_output" | awk '/^Jinja/ {print $NF}')
    local java_loc=$(echo "$cloc_output" | awk '/^Java / {print $NF}')
    local kotlin_loc=$(echo "$cloc_output" | awk '/^Kotlin/ {print $NF}')
    local rust_loc=$(echo "$cloc_output" | awk '/^Rust/ {print $NF}')
    local go_loc=$(echo "$cloc_output" | awk '/^Go / {print $NF}')
    local python_loc=$(echo "$cloc_output" | awk '/^Python/ {print $NF}')
    local csharp_loc=$(echo "$cloc_output" | awk '/^C#/ {print $NF}')
    local ruby_loc=$(echo "$cloc_output" | awk '/^Ruby/ {print $NF}')
    local swift_loc=$(echo "$cloc_output" | awk '/^Swift/ {print $NF}')
    local scala_loc=$(echo "$cloc_output" | awk '/^Scala/ {print $NF}')
    local dart_loc=$(echo "$cloc_output" | awk '/^Dart/ {print $NF}')
    local c_loc=$(echo "$cloc_output" | awk '/^C[[:space:]]+[0-9]/ {print $NF}')
    local cpp_loc=$(echo "$cloc_output" | awk '/^C\+\+/ {print $NF}')
    local shell_loc=$(echo "$cloc_output" | awk '/^(Bourne (Again )?)?Shell/ {sum += $NF} END {print sum+0}')
    local sql_loc=$(echo "$cloc_output" | awk '/^SQL/ {print $NF}')
    local html_loc=$(echo "$cloc_output" | awk '/^HTML/ {print $NF}')
    local css_loc=$(echo "$cloc_output" | awk '/^(CSS|SASS|SCSS)/ {sum += $NF} END {print sum+0}')
    local yaml_loc=$(echo "$cloc_output" | awk '/^YAML/ {print $NF}')

    # Default to 0 if empty
    php_loc=${php_loc:-0}; js_loc=${js_loc:-0}; ts_loc=${ts_loc:-0}
    twig_loc=${twig_loc:-0}; jinja2_loc=${jinja2_loc:-0}
    java_loc=${java_loc:-0}; kotlin_loc=${kotlin_loc:-0}
    rust_loc=${rust_loc:-0}; go_loc=${go_loc:-0}
    python_loc=${python_loc:-0}; csharp_loc=${csharp_loc:-0}
    ruby_loc=${ruby_loc:-0}; swift_loc=${swift_loc:-0}
    scala_loc=${scala_loc:-0}; dart_loc=${dart_loc:-0}
    c_loc=${c_loc:-0}; cpp_loc=${cpp_loc:-0}
    shell_loc=${shell_loc:-0}; sql_loc=${sql_loc:-0}
    html_loc=${html_loc:-0}; css_loc=${css_loc:-0}; yaml_loc=${yaml_loc:-0}

    # Calculate graduated template contributions (Twig, Jinja2)
    local twig_contribution
    twig_contribution=$(calculate_template_contribution "$twig_loc")
    local jinja2_contribution
    jinja2_contribution=$(calculate_template_contribution "$jinja2_loc")

    # HTML/CSS/YAML get similar graduated treatment
    local html_contribution
    html_contribution=$(calculate_template_contribution "$html_loc")
    local css_contribution
    css_contribution=$(calculate_template_contribution "$css_loc")
    local yaml_contribution
    yaml_contribution=$(calculate_template_contribution "$yaml_loc")

    # Display LOC breakdown as table
    section_header "1" "Lines of Code Analysis"
    printf "  ${DIM}%-14s %8s %10s${NC}\n" "Language" "LOC" "Rate/day"
    printf "  ${DIM}%-14s %8s %10s${NC}\n" "──────────────" "────────" "──────────"

    # Code languages (full LOC counted)
    [ "$php_loc" -gt 0 ] && printf "  ${GREEN}${BULLET}${NC} %-12s ${WHITE}%8s${NC} %10s\n" "PHP" "$php_loc" "$PHP_RATE"
    [ "$js_loc" -gt 0 ] && printf "  ${YELLOW}${BULLET}${NC} %-12s ${WHITE}%8s${NC} %10s\n" "JavaScript" "$js_loc" "$JS_RATE"
    [ "$ts_loc" -gt 0 ] && printf "  ${BLUE}${BULLET}${NC} %-12s ${WHITE}%8s${NC} %10s\n" "TypeScript" "$ts_loc" "$TS_RATE"
    [ "$java_loc" -gt 0 ] && printf "  ${RED}${BULLET}${NC} %-12s ${WHITE}%8s${NC} %10s\n" "Java" "$java_loc" "$JAVA_RATE"
    [ "$kotlin_loc" -gt 0 ] && printf "  ${MAGENTA}${BULLET}${NC} %-12s ${WHITE}%8s${NC} %10s\n" "Kotlin" "$kotlin_loc" "$KOTLIN_RATE"
    [ "$rust_loc" -gt 0 ] && printf "  ${RED}${BULLET}${NC} %-12s ${WHITE}%8s${NC} %10s\n" "Rust" "$rust_loc" "$RUST_RATE"
    [ "$go_loc" -gt 0 ] && printf "  ${CYAN}${BULLET}${NC} %-12s ${WHITE}%8s${NC} %10s\n" "Go" "$go_loc" "$GO_RATE"
    [ "$python_loc" -gt 0 ] && printf "  ${YELLOW}${BULLET}${NC} %-12s ${WHITE}%8s${NC} %10s\n" "Python" "$python_loc" "$PYTHON_RATE"
    [ "$csharp_loc" -gt 0 ] && printf "  ${GREEN}${BULLET}${NC} %-12s ${WHITE}%8s${NC} %10s\n" "C#" "$csharp_loc" "$CSHARP_RATE"
    [ "$ruby_loc" -gt 0 ] && printf "  ${RED}${BULLET}${NC} %-12s ${WHITE}%8s${NC} %10s\n" "Ruby" "$ruby_loc" "$RUBY_RATE"
    [ "$swift_loc" -gt 0 ] && printf "  ${YELLOW}${BULLET}${NC} %-12s ${WHITE}%8s${NC} %10s\n" "Swift" "$swift_loc" "$SWIFT_RATE"
    [ "$scala_loc" -gt 0 ] && printf "  ${RED}${BULLET}${NC} %-12s ${WHITE}%8s${NC} %10s\n" "Scala" "$scala_loc" "$SCALA_RATE"
    [ "$dart_loc" -gt 0 ] && printf "  ${CYAN}${BULLET}${NC} %-12s ${WHITE}%8s${NC} %10s\n" "Dart" "$dart_loc" "$DART_RATE"
    [ "$c_loc" -gt 0 ] && printf "  ${GRAY}${BULLET}${NC} %-12s ${WHITE}%8s${NC} %10s\n" "C" "$c_loc" "$C_RATE"
    [ "$cpp_loc" -gt 0 ] && printf "  ${GRAY}${BULLET}${NC} %-12s ${WHITE}%8s${NC} %10s\n" "C++" "$cpp_loc" "$CPP_RATE"
    [ "$shell_loc" -gt 0 ] && printf "  ${GREEN}${BULLET}${NC} %-12s ${WHITE}%8s${NC} %10s\n" "Shell" "$shell_loc" "$SHELL_RATE"
    [ "$sql_loc" -gt 0 ] && printf "  ${BLUE}${BULLET}${NC} %-12s ${WHITE}%8s${NC} %10s\n" "SQL" "$sql_loc" "$SQL_RATE"

    # Template/markup languages (weighted contribution)
    if [ "$twig_loc" -gt 0 ]; then
        if [ "$twig_contribution" -gt 0 ]; then
            local twig_pct; if [ "$twig_loc" -gt 500 ]; then twig_pct="30%"; else twig_pct="15%"; fi
            printf "  ${GRAY}${BULLET}${NC} %-12s ${WHITE}%8s${NC} %10s ${DIM}(weighted: %s at %s)${NC}\n" "Twig" "$twig_loc" "$TWIG_RATE" "$twig_contribution" "$twig_pct"
        else
            printf "  ${GRAY}${BULLET}${NC} %-12s ${DIM}%8s${NC} %10s ${DIM}(below threshold)${NC}\n" "Twig" "$twig_loc" "-"
        fi
    fi
    if [ "$jinja2_loc" -gt 0 ]; then
        if [ "$jinja2_contribution" -gt 0 ]; then
            local j2_pct; if [ "$jinja2_loc" -gt 500 ]; then j2_pct="30%"; else j2_pct="15%"; fi
            printf "  ${GRAY}${BULLET}${NC} %-12s ${WHITE}%8s${NC} %10s ${DIM}(weighted: %s at %s)${NC}\n" "Jinja2" "$jinja2_loc" "$JINJA2_RATE" "$jinja2_contribution" "$j2_pct"
        else
            printf "  ${GRAY}${BULLET}${NC} %-12s ${DIM}%8s${NC} %10s ${DIM}(below threshold)${NC}\n" "Jinja2" "$jinja2_loc" "-"
        fi
    fi
    if [ "$html_loc" -gt 0 ]; then
        if [ "$html_contribution" -gt 0 ]; then
            local html_pct; if [ "$html_loc" -gt 500 ]; then html_pct="30%"; else html_pct="15%"; fi
            printf "  ${GRAY}${BULLET}${NC} %-12s ${WHITE}%8s${NC} %10s ${DIM}(weighted: %s at %s)${NC}\n" "HTML" "$html_loc" "$HTML_RATE" "$html_contribution" "$html_pct"
        else
            printf "  ${GRAY}${BULLET}${NC} %-12s ${DIM}%8s${NC} %10s ${DIM}(below threshold)${NC}\n" "HTML" "$html_loc" "-"
        fi
    fi
    if [ "$css_loc" -gt 0 ]; then
        if [ "$css_contribution" -gt 0 ]; then
            local css_pct; if [ "$css_loc" -gt 500 ]; then css_pct="30%"; else css_pct="15%"; fi
            printf "  ${GRAY}${BULLET}${NC} %-12s ${WHITE}%8s${NC} %10s ${DIM}(weighted: %s at %s)${NC}\n" "CSS/SCSS" "$css_loc" "$CSS_RATE" "$css_contribution" "$css_pct"
        else
            printf "  ${GRAY}${BULLET}${NC} %-12s ${DIM}%8s${NC} %10s ${DIM}(below threshold)${NC}\n" "CSS/SCSS" "$css_loc" "-"
        fi
    fi
    if [ "$yaml_loc" -gt 0 ]; then
        if [ "$yaml_contribution" -gt 0 ]; then
            local yaml_pct; if [ "$yaml_loc" -gt 500 ]; then yaml_pct="30%"; else yaml_pct="15%"; fi
            printf "  ${GRAY}${BULLET}${NC} %-12s ${WHITE}%8s${NC} %10s ${DIM}(weighted: %s at %s)${NC}\n" "YAML" "$yaml_loc" "$YAML_RATE" "$yaml_contribution" "$yaml_pct"
        else
            printf "  ${GRAY}${BULLET}${NC} %-12s ${DIM}%8s${NC} %10s ${DIM}(below threshold)${NC}\n" "YAML" "$yaml_loc" "-"
        fi
    fi

    # Total LOC for display purposes (code langs at full, templates weighted)
    local total_loc=$((php_loc + js_loc + ts_loc + java_loc + kotlin_loc + rust_loc + go_loc + python_loc + csharp_loc + ruby_loc + swift_loc + scala_loc + dart_loc + c_loc + cpp_loc + shell_loc + sql_loc + twig_contribution + jinja2_contribution + html_contribution + css_contribution + yaml_contribution))
    printf "  ${DIM}%-14s${NC} ${BOLD}${WHITE}%8s${NC}\n" "──────────────" "────────"
    printf "  ${BOLD}  Total LOC${NC}    ${BOLD}${WHITE}%8s${NC}\n" "$total_loc"

    # Calculate base effort using per-language rates
    section_header "2" "Base Effort (per-language rates)"
    local base_effort
    base_effort=$(awk "BEGIN {printf \"%.6f\", \
        $php_loc/$PHP_RATE + $js_loc/$JS_RATE + $ts_loc/$TS_RATE + \
        $java_loc/$JAVA_RATE + $kotlin_loc/$KOTLIN_RATE + \
        $rust_loc/$RUST_RATE + $go_loc/$GO_RATE + \
        $python_loc/$PYTHON_RATE + $csharp_loc/$CSHARP_RATE + \
        $ruby_loc/$RUBY_RATE + $swift_loc/$SWIFT_RATE + \
        $scala_loc/$SCALA_RATE + $dart_loc/$DART_RATE + \
        $c_loc/$C_RATE + $cpp_loc/$CPP_RATE + \
        $shell_loc/$SHELL_RATE + $sql_loc/$SQL_RATE + \
        $twig_contribution/$TWIG_RATE + $jinja2_contribution/$JINJA2_RATE + \
        $html_contribution/$HTML_RATE + $css_contribution/$CSS_RATE + \
        $yaml_contribution/$YAML_RATE}")

    [ "$php_loc" -gt 0 ] && printf "  ${DIM}PHP:${NC}        %6s ÷ %s = ${WHITE}%s${NC} days ${DIM}(%s)${NC}\n" "$php_loc" "$PHP_RATE" "$(awk "BEGIN {printf \"%.4f\", $php_loc/$PHP_RATE}")" "$(days_to_hm "$(awk "BEGIN {printf \"%.6f\", $php_loc/$PHP_RATE}")")"
    [ "$js_loc" -gt 0 ] && printf "  ${DIM}JS:${NC}         %6s ÷ %s = ${WHITE}%s${NC} days ${DIM}(%s)${NC}\n" "$js_loc" "$JS_RATE" "$(awk "BEGIN {printf \"%.4f\", $js_loc/$JS_RATE}")" "$(days_to_hm "$(awk "BEGIN {printf \"%.6f\", $js_loc/$JS_RATE}")")"
    [ "$ts_loc" -gt 0 ] && printf "  ${DIM}TypeScript:${NC} %6s ÷ %s = ${WHITE}%s${NC} days ${DIM}(%s)${NC}\n" "$ts_loc" "$TS_RATE" "$(awk "BEGIN {printf \"%.4f\", $ts_loc/$TS_RATE}")" "$(days_to_hm "$(awk "BEGIN {printf \"%.6f\", $ts_loc/$TS_RATE}")")"
    [ "$java_loc" -gt 0 ] && printf "  ${DIM}Java:${NC}       %6s ÷ %s = ${WHITE}%s${NC} days ${DIM}(%s)${NC}\n" "$java_loc" "$JAVA_RATE" "$(awk "BEGIN {printf \"%.4f\", $java_loc/$JAVA_RATE}")" "$(days_to_hm "$(awk "BEGIN {printf \"%.6f\", $java_loc/$JAVA_RATE}")")"
    [ "$kotlin_loc" -gt 0 ] && printf "  ${DIM}Kotlin:${NC}     %6s ÷ %s = ${WHITE}%s${NC} days ${DIM}(%s)${NC}\n" "$kotlin_loc" "$KOTLIN_RATE" "$(awk "BEGIN {printf \"%.4f\", $kotlin_loc/$KOTLIN_RATE}")" "$(days_to_hm "$(awk "BEGIN {printf \"%.6f\", $kotlin_loc/$KOTLIN_RATE}")")"
    [ "$rust_loc" -gt 0 ] && printf "  ${DIM}Rust:${NC}       %6s ÷ %s = ${WHITE}%s${NC} days ${DIM}(%s)${NC}\n" "$rust_loc" "$RUST_RATE" "$(awk "BEGIN {printf \"%.4f\", $rust_loc/$RUST_RATE}")" "$(days_to_hm "$(awk "BEGIN {printf \"%.6f\", $rust_loc/$RUST_RATE}")")"
    [ "$go_loc" -gt 0 ] && printf "  ${DIM}Go:${NC}         %6s ÷ %s = ${WHITE}%s${NC} days ${DIM}(%s)${NC}\n" "$go_loc" "$GO_RATE" "$(awk "BEGIN {printf \"%.4f\", $go_loc/$GO_RATE}")" "$(days_to_hm "$(awk "BEGIN {printf \"%.6f\", $go_loc/$GO_RATE}")")"
    [ "$python_loc" -gt 0 ] && printf "  ${DIM}Python:${NC}     %6s ÷ %s = ${WHITE}%s${NC} days ${DIM}(%s)${NC}\n" "$python_loc" "$PYTHON_RATE" "$(awk "BEGIN {printf \"%.4f\", $python_loc/$PYTHON_RATE}")" "$(days_to_hm "$(awk "BEGIN {printf \"%.6f\", $python_loc/$PYTHON_RATE}")")"
    [ "$csharp_loc" -gt 0 ] && printf "  ${DIM}C#:${NC}         %6s ÷ %s = ${WHITE}%s${NC} days ${DIM}(%s)${NC}\n" "$csharp_loc" "$CSHARP_RATE" "$(awk "BEGIN {printf \"%.4f\", $csharp_loc/$CSHARP_RATE}")" "$(days_to_hm "$(awk "BEGIN {printf \"%.6f\", $csharp_loc/$CSHARP_RATE}")")"
    [ "$ruby_loc" -gt 0 ] && printf "  ${DIM}Ruby:${NC}       %6s ÷ %s = ${WHITE}%s${NC} days ${DIM}(%s)${NC}\n" "$ruby_loc" "$RUBY_RATE" "$(awk "BEGIN {printf \"%.4f\", $ruby_loc/$RUBY_RATE}")" "$(days_to_hm "$(awk "BEGIN {printf \"%.6f\", $ruby_loc/$RUBY_RATE}")")"
    [ "$swift_loc" -gt 0 ] && printf "  ${DIM}Swift:${NC}      %6s ÷ %s = ${WHITE}%s${NC} days ${DIM}(%s)${NC}\n" "$swift_loc" "$SWIFT_RATE" "$(awk "BEGIN {printf \"%.4f\", $swift_loc/$SWIFT_RATE}")" "$(days_to_hm "$(awk "BEGIN {printf \"%.6f\", $swift_loc/$SWIFT_RATE}")")"
    [ "$scala_loc" -gt 0 ] && printf "  ${DIM}Scala:${NC}      %6s ÷ %s = ${WHITE}%s${NC} days ${DIM}(%s)${NC}\n" "$scala_loc" "$SCALA_RATE" "$(awk "BEGIN {printf \"%.4f\", $scala_loc/$SCALA_RATE}")" "$(days_to_hm "$(awk "BEGIN {printf \"%.6f\", $scala_loc/$SCALA_RATE}")")"
    [ "$dart_loc" -gt 0 ] && printf "  ${DIM}Dart:${NC}       %6s ÷ %s = ${WHITE}%s${NC} days ${DIM}(%s)${NC}\n" "$dart_loc" "$DART_RATE" "$(awk "BEGIN {printf \"%.4f\", $dart_loc/$DART_RATE}")" "$(days_to_hm "$(awk "BEGIN {printf \"%.6f\", $dart_loc/$DART_RATE}")")"
    [ "$c_loc" -gt 0 ] && printf "  ${DIM}C:${NC}          %6s ÷ %s = ${WHITE}%s${NC} days ${DIM}(%s)${NC}\n" "$c_loc" "$C_RATE" "$(awk "BEGIN {printf \"%.4f\", $c_loc/$C_RATE}")" "$(days_to_hm "$(awk "BEGIN {printf \"%.6f\", $c_loc/$C_RATE}")")"
    [ "$cpp_loc" -gt 0 ] && printf "  ${DIM}C++:${NC}        %6s ÷ %s = ${WHITE}%s${NC} days ${DIM}(%s)${NC}\n" "$cpp_loc" "$CPP_RATE" "$(awk "BEGIN {printf \"%.4f\", $cpp_loc/$CPP_RATE}")" "$(days_to_hm "$(awk "BEGIN {printf \"%.6f\", $cpp_loc/$CPP_RATE}")")"
    [ "$shell_loc" -gt 0 ] && printf "  ${DIM}Shell:${NC}      %6s ÷ %s = ${WHITE}%s${NC} days ${DIM}(%s)${NC}\n" "$shell_loc" "$SHELL_RATE" "$(awk "BEGIN {printf \"%.4f\", $shell_loc/$SHELL_RATE}")" "$(days_to_hm "$(awk "BEGIN {printf \"%.6f\", $shell_loc/$SHELL_RATE}")")"
    [ "$sql_loc" -gt 0 ] && printf "  ${DIM}SQL:${NC}        %6s ÷ %s = ${WHITE}%s${NC} days ${DIM}(%s)${NC}\n" "$sql_loc" "$SQL_RATE" "$(awk "BEGIN {printf \"%.4f\", $sql_loc/$SQL_RATE}")" "$(days_to_hm "$(awk "BEGIN {printf \"%.6f\", $sql_loc/$SQL_RATE}")")"
    [ "$twig_contribution" -gt 0 ] && printf "  ${DIM}Twig:${NC}       %6s ÷ %s = ${WHITE}%s${NC} days ${DIM}(%s)${NC}\n" "$twig_contribution" "$TWIG_RATE" "$(awk "BEGIN {printf \"%.4f\", $twig_contribution/$TWIG_RATE}")" "$(days_to_hm "$(awk "BEGIN {printf \"%.6f\", $twig_contribution/$TWIG_RATE}")")"
    [ "$jinja2_contribution" -gt 0 ] && printf "  ${DIM}Jinja2:${NC}     %6s ÷ %s = ${WHITE}%s${NC} days ${DIM}(%s)${NC}\n" "$jinja2_contribution" "$JINJA2_RATE" "$(awk "BEGIN {printf \"%.4f\", $jinja2_contribution/$JINJA2_RATE}")" "$(days_to_hm "$(awk "BEGIN {printf \"%.6f\", $jinja2_contribution/$JINJA2_RATE}")")"
    [ "$html_contribution" -gt 0 ] && printf "  ${DIM}HTML:${NC}       %6s ÷ %s = ${WHITE}%s${NC} days ${DIM}(%s)${NC}\n" "$html_contribution" "$HTML_RATE" "$(awk "BEGIN {printf \"%.4f\", $html_contribution/$HTML_RATE}")" "$(days_to_hm "$(awk "BEGIN {printf \"%.6f\", $html_contribution/$HTML_RATE}")")"
    [ "$css_contribution" -gt 0 ] && printf "  ${DIM}CSS/SCSS:${NC}   %6s ÷ %s = ${WHITE}%s${NC} days ${DIM}(%s)${NC}\n" "$css_contribution" "$CSS_RATE" "$(awk "BEGIN {printf \"%.4f\", $css_contribution/$CSS_RATE}")" "$(days_to_hm "$(awk "BEGIN {printf \"%.6f\", $css_contribution/$CSS_RATE}")")"
    [ "$yaml_contribution" -gt 0 ] && printf "  ${DIM}YAML:${NC}       %6s ÷ %s = ${WHITE}%s${NC} days ${DIM}(%s)${NC}\n" "$yaml_contribution" "$YAML_RATE" "$(awk "BEGIN {printf \"%.4f\", $yaml_contribution/$YAML_RATE}")" "$(days_to_hm "$(awk "BEGIN {printf \"%.6f\", $yaml_contribution/$YAML_RATE}")")"

    printf "\n  ${ARROW} ${BOLD}Base effort: ${GREEN}%s days${NC} ${DIM}(%s)${NC}\n" "$base_effort" "$(days_to_hm "$base_effort")"

    # Calculate coupling factor
    section_header "3" "Automated Analysis"
    printf "  ${DIM}Scanning dependencies...${NC} "
    local coupling_factor
    coupling_factor=$(calculate_coupling_factor "$path")
    if [ "$coupling_factor" != "1.00" ]; then
        printf "${YELLOW}coupling ×%s${NC}\n" "$coupling_factor"
    else
        printf "${GREEN}${CHECK} coupling ×%s${NC}\n" "$coupling_factor"
    fi

    printf "  ${DIM}Analyzing git history...${NC} "
    local churn_factor
    churn_factor=$(calculate_churn_factor "$path")
    if [ "$churn_factor" != "1.00" ]; then
        printf "${YELLOW}churn ×%s${NC}\n" "$churn_factor"
    else
        printf "${GREEN}${CHECK} churn ×%s${NC}\n" "$churn_factor"
    fi

    # Complexity selection
    section_header "4" "Work Type & Complexity"
    local selection_type=""
    local complexity_factor=""

    if [ "$non_interactive" = true ]; then
        # Resolve work type from preset
        local ni_type_name=""
        case "$PRESET_TYPE" in
            enhancement) ni_type_name="Enhancement" ;;
            bugfix) ni_type_name="Bugfix" ;;
            version) ni_type_name="Version Compatibility" ;;
            refactoring) ni_type_name="Refactoring" ;;
            *)
                printf "  ${RED}Unknown preset type: '%s'${NC}\n" "$PRESET_TYPE"
                printf "  ${DIM}Valid: enhancement, bugfix, version, refactoring${NC}\n"
                exit 1
                ;;
        esac

        local ni_levels=($(get_complexity_options "$ni_type_name" "levels"))
        local ni_factors=($(get_complexity_options "$ni_type_name" "factors"))
        local ni_idx=$((PRESET_COMPLEXITY - 1))

        # Guard against out-of-range complexity level
        if [ "$ni_idx" -lt 0 ] || [ "$ni_idx" -ge "${#ni_levels[@]}" ]; then
            printf "  ${RED}Complexity level %s out of range for %s (1-%d)${NC}\n" "$PRESET_COMPLEXITY" "$ni_type_name" "${#ni_levels[@]}"
            exit 1
        fi

        selection_type="$ni_type_name - ${ni_levels[$ni_idx]//_/ }"
        complexity_factor="${ni_factors[$ni_idx]}"
        printf "  ${DIM}(preset) %s (×%s)${NC}\n" "$selection_type" "$complexity_factor"
    else
        options=("Enhancement" "Bugfix" "Version Compatibility" "Refactoring")
        PS3=$'\n  Select work type (1-4): '
        select opt in "${options[@]}"; do
            if [[ -n "$opt" ]]; then
                local levels=($(get_complexity_options "$opt" "levels"))
                local factors=($(get_complexity_options "$opt" "factors"))

                PS3=$'\n  Select complexity level (1-'"${#levels[@]}"'): '
                select level in "${levels[@]}"; do
                    if [[ -n "$level" ]] && ((REPLY > 0 && REPLY <= ${#levels[@]})); then
                        local index=$((REPLY-1))
                        selection_type="$opt - ${level//_/ }"
                        complexity_factor="${factors[$index]}"
                        break 2
                    else
                        printf "  ${RED}Please select a valid option (1-${#levels[@]})${NC}\n"
                    fi
                done
            else
                printf "  ${RED}Please select a valid option (1-${#options[@]})${NC}\n"
            fi
        done
    fi

    printf "\n  ${ARROW} Selected: ${BOLD}%s${NC} ${DIM}(×%s)${NC}\n" "$selection_type" "$complexity_factor"

    # Familiarity factor — whether the developer knows this codebase
    # One of the biggest real-world multipliers for productivity
    section_header "4b" "Codebase Familiarity"
    local familiarity_factor="1.00"

    if [ "$non_interactive" = true ]; then
        case "$PRESET_FAMILIARITY" in
            1) familiarity_factor="1.00" ;;
            2) familiarity_factor="1.15" ;;
            3) familiarity_factor="1.40" ;;
            4) familiarity_factor="1.70" ;;
            *)
                printf "  ${RED}Invalid familiarity level: %s (valid: 1-4)${NC}\n" "$PRESET_FAMILIARITY"
                exit 1
                ;;
        esac
        printf "  ${DIM}(preset) Familiarity: ×%s${NC}\n" "$familiarity_factor"
    else
        printf "  ${DIM}How well do you know this codebase?${NC}\n"
        echo ""
        local fam_options=("Own code (wrote it myself)" "Team code (familiar, reviewed it)" "Inherited (read it, know the gist)" "Unknown (never seen before)")
        PS3=$'\n  Select familiarity level (1-4): '
        select fam_opt in "${fam_options[@]}"; do
            if [[ -n "$fam_opt" ]]; then
                case $REPLY in
                    1) familiarity_factor="1.00" ;;
                    2) familiarity_factor="1.15" ;;  # Small overhead for context gaps
                    3) familiarity_factor="1.40" ;;  # Significant reading/understanding time
                    4) familiarity_factor="1.70" ;;  # Major ramp-up cost
                esac
                break
            else
                printf "  ${RED}Please select a valid option (1-4)${NC}\n"
            fi
        done
    fi

    if [ "$familiarity_factor" != "1.00" ]; then
        printf "\n  ${YELLOW}${ARROW} Familiarity overhead: ×%s${NC}\n" "$familiarity_factor"
    else
        printf "\n  ${GREEN}${CHECK} Own code — no familiarity overhead${NC}\n"
    fi

    # Testing overhead question
    section_header "5" "Testing Overhead"
    local testing_factor="1.00"

    if [ "$non_interactive" = true ]; then
        if [[ "$PRESET_TESTING" =~ ^[Yy]$ ]]; then
            testing_factor="1.30"
            printf "  ${DIM}(preset) Testing: ×1.30${NC}\n"
        else
            testing_factor="1.00"
            printf "  ${DIM}(preset) Testing: ×1.00${NC}\n"
        fi
    else
        printf "  "
        read -p "Does this work require creating/updating tests? (y/n): " needs_tests
        if [[ "$needs_tests" =~ ^[Yy]$ ]]; then
            testing_factor="1.30"
            printf "  ${YELLOW}${ARROW} Testing overhead: ×1.30 (+30%%)${NC}\n"
        else
            printf "  ${GREEN}${CHECK} No testing overhead${NC}\n"
        fi
    fi

    # Documentation overhead question
    section_header "6" "Documentation Updates"
    local doc_effort_days="0.000000"
    local doc_level="None"

    if [ "$non_interactive" = true ]; then
        case "$PRESET_DOC" in
            1) doc_effort_days="0.000000"; doc_level="None" ;;
            2) doc_effort_days="0.125000"; doc_level="Minor" ;;
            3) doc_effort_days="0.375000"; doc_level="Standard" ;;
            4) doc_effort_days="0.750000"; doc_level="Extensive" ;;
            *)
                printf "  ${RED}Invalid doc level: %s (valid: 1-4)${NC}\n" "$PRESET_DOC"
                exit 1
                ;;
        esac
        printf "  ${DIM}(preset) Documentation: %s${NC}\n" "$doc_level"
    else
        printf "  ${DIM}Will this work require documentation updates?${NC}\n"
        printf "  ${DIM}(README, API docs, architecture docs, changelogs, etc.)${NC}\n"
        echo ""

        local doc_options=("None" "Minor (changelog, comments)" "Standard (README, API docs)" "Extensive (architecture, guides, specs)")
        PS3=$'\n  Select documentation level (1-4): '
        select doc_opt in "${doc_options[@]}"; do
            if [[ -n "$doc_opt" ]]; then
                case $REPLY in
                    1) doc_effort_days="0.000000"; doc_level="None" ;;
                    2) doc_effort_days="0.125000"; doc_level="Minor"; ;; # 1 hour
                    3) doc_effort_days="0.375000"; doc_level="Standard"; ;; # 3 hours
                    4) doc_effort_days="0.750000"; doc_level="Extensive"; ;; # 6 hours
                esac
                break
            else
                printf "  ${RED}Please select a valid option (1-4)${NC}\n"
            fi
        done
    fi

    if [ "$doc_level" != "None" ]; then
        local doc_hours
        doc_hours=$(awk "BEGIN {printf \"%d\", int($doc_effort_days * 8)}")
        local doc_mins
        doc_mins=$(awk "BEGIN {printf \"%d\", ($doc_effort_days * 8 - int($doc_effort_days * 8)) * 60}")
        printf "\n  ${YELLOW}${ARROW} Documentation: +%s days (%s h %s min) — %s${NC}\n" "$doc_effort_days" "$doc_hours" "$doc_mins" "$doc_level"
    else
        printf "\n  ${GREEN}${CHECK} No documentation overhead${NC}\n"
    fi

    # AI LLM assistance question
    section_header "7" "AI-Assisted Development (LLM)"
    local ai_coding_factor="1.00"
    local ai_overhead_days="0.000000"
    local ai_level="None"

    if [ "$non_interactive" = true ]; then
        case "$PRESET_AI" in
            1)
                ai_coding_factor="1.00"
                ai_overhead_days="0.000000"
                ai_level="None"
                ;;
            2)
                ai_coding_factor="0.85"
                ai_overhead_days=$(awk "BEGIN {v = $base_effort * 0.05; if (v < 0.125) v = 0.125; printf \"%.6f\", v}")
                ai_level="Light"
                ;;
            3)
                ai_coding_factor="0.65"
                ai_overhead_days=$(awk "BEGIN {v = $base_effort * 0.10; if (v < 0.250) v = 0.250; printf \"%.6f\", v}")
                ai_level="Moderate"
                ;;
            4)
                ai_coding_factor="0.45"
                ai_overhead_days=$(awk "BEGIN {v = $base_effort * 0.15; if (v < 0.500) v = 0.500; printf \"%.6f\", v}")
                ai_level="Heavy (Agentic AI)"
                ;;
            *)
                printf "  ${RED}Invalid AI level: %s (valid: 1-4)${NC}\n" "$PRESET_AI"
                exit 1
                ;;
        esac
        printf "  ${DIM}(preset) AI: %s (×%s, +%s days overhead)${NC}\n" "$ai_level" "$ai_coding_factor" "$ai_overhead_days"
    else
        printf "  ${DIM}Will you use AI/LLM assistance (e.g., Claude Opus, GPT-4)?${NC}\n"
        printf "  ${DIM}This reduces coding effort but adds overhead for:${NC}\n"
        printf "  ${DIM}  - Requirements Engineering & prompt crafting${NC}\n"
        printf "  ${DIM}  - Code review & validation of AI output${NC}\n"
        printf "  ${DIM}  - Integration with agentic workflows${NC}\n"
        printf "  ${DIM}  (see: github.com/cr-solutions/Requirements-Engineering-Agentic-AI)${NC}\n"
        echo ""

        local ai_options=("No AI assistance" "Light (code suggestions, autocomplete)" "Moderate (feature generation, refactoring)" "Heavy (agentic AI, full workflow with RE)")
        PS3=$'\n  Select AI assistance level (1-4): '
        select ai_opt in "${ai_options[@]}"; do
            if [[ -n "$ai_opt" ]]; then
                case $REPLY in
                    1)
                        ai_coding_factor="1.00"
                        ai_overhead_days="0.000000"
                        ai_level="None"
                        ;;
                    2)
                        ai_coding_factor="0.85"   # 15% coding reduction
                        # Overhead scales with base effort: minimum 1h, grows with project size
                        ai_overhead_days=$(awk "BEGIN {v = $base_effort * 0.05; if (v < 0.125) v = 0.125; printf \"%.6f\", v}")
                        ai_level="Light"
                        ;;
                    3)
                        ai_coding_factor="0.65"   # 35% coding reduction
                        # Overhead scales: minimum 2h, ~10% of base for prompt engineering + review
                        ai_overhead_days=$(awk "BEGIN {v = $base_effort * 0.10; if (v < 0.250) v = 0.250; printf \"%.6f\", v}")
                        ai_level="Moderate"
                        ;;
                    4)
                        ai_coding_factor="0.45"   # 55% coding reduction
                        # Overhead scales: minimum 4h, ~15% of base for RE workflow + validation
                        ai_overhead_days=$(awk "BEGIN {v = $base_effort * 0.15; if (v < 0.500) v = 0.500; printf \"%.6f\", v}")
                        ai_level="Heavy (Agentic AI)"
                        ;;
                esac
                break
            else
                printf "  ${RED}Please select a valid option (1-4)${NC}\n"
            fi
        done
    fi

    if [ "$ai_level" != "None" ]; then
        local ai_oh_hours
        ai_oh_hours=$(awk "BEGIN {printf \"%d\", int($ai_overhead_days * 8)}")
        local ai_oh_mins
        ai_oh_mins=$(awk "BEGIN {printf \"%d\", ($ai_overhead_days * 8 - int($ai_overhead_days * 8)) * 60}")
        printf "\n  ${CYAN}${ARROW} AI coding reduction: ×%s (-%s%% coding effort)${NC}\n" \
            "$ai_coding_factor" "$(awk "BEGIN {printf \"%d\", (1 - $ai_coding_factor) * 100}")"
        printf "  ${CYAN}${ARROW} AI overhead (RE/prompts/review): +%s days (%s h %s min)${NC}\n" \
            "$ai_overhead_days" "$ai_oh_hours" "$ai_oh_mins"
    else
        printf "\n  ${GREEN}${CHECK} No AI assistance — full manual effort${NC}\n"
    fi

    # Calculate final effort with all factors
    # Familiarity and complexity multiply the base, AI reduces coding portion, then fixed overheads added
    local final_effort
    final_effort=$(awk "BEGIN {printf \"%.6f\", ($base_effort * $complexity_factor * $familiarity_factor * $coupling_factor * $churn_factor * $testing_factor * $ai_coding_factor) + $doc_effort_days + $ai_overhead_days}")

    # Apply minimum effort floor
    local floored=false
    if (( $(awk "BEGIN {print ($final_effort < $MIN_EFFORT_DAYS) ? 1 : 0}") )); then
        final_effort="$MIN_EFFORT_DAYS"
        floored=true
    fi

    # Calculate total hours and split into hours and minutes using awk
    local total_hours
    total_hours=$(awk "BEGIN {printf \"%.6f\", $final_effort * 8}")

    local full_hours
    full_hours=$(awk "BEGIN {printf \"%d\", int($total_hours)}")

    local minutes
    minutes=$(awk "BEGIN {printf \"%d\", ($total_hours - int($total_hours)) * 60}")

    # Also calculate what coding-only effort is (for display)
    local coding_effort
    coding_effort=$(awk "BEGIN {printf \"%.6f\", $base_effort * $complexity_factor * $familiarity_factor * $coupling_factor * $churn_factor * $testing_factor * $ai_coding_factor}")

    # Final results box
    echo ""
    printf "  ${CYAN}${BOX_TL}"
    printf '%0.s'"$BOX_H" $(seq 1 58)
    printf "${NC}\n"
    printf "  ${CYAN}${BOX_V}${NC} ${BOLD}${WHITE}CALCULATION BREAKDOWN${NC}\n"
    printf "  ${CYAN}${BOX_ML}"
    printf '%0.s'"$BOX_H" $(seq 1 58)
    printf "${NC}\n"

    printf "  ${CYAN}${BOX_V}${NC}  ${DIM}Base effort:${NC}       %s days ${DIM}(%s)${NC}\n" "$base_effort" "$(days_to_hm "$base_effort")"
    printf "  ${CYAN}${BOX_V}${NC}  ${DIM}Complexity:${NC}        ×%s (%s)\n" "$complexity_factor" "$selection_type"
    printf "  ${CYAN}${BOX_V}${NC}  ${DIM}Familiarity:${NC}       ×%s\n" "$familiarity_factor"
    printf "  ${CYAN}${BOX_V}${NC}  ${DIM}Coupling:${NC}          ×%s\n" "$coupling_factor"
    printf "  ${CYAN}${BOX_V}${NC}  ${DIM}Churn:${NC}             ×%s\n" "$churn_factor"
    printf "  ${CYAN}${BOX_V}${NC}  ${DIM}Testing:${NC}           ×%s\n" "$testing_factor"
    if [ "$ai_level" != "None" ]; then
        printf "  ${CYAN}${BOX_V}${NC}  ${DIM}AI reduction:${NC}      ×%s (%s)\n" "$ai_coding_factor" "$ai_level"
    fi
    printf "  ${CYAN}${BOX_V}${NC}  ${DIM}─────────────────────────────${NC}\n"
    printf "  ${CYAN}${BOX_V}${NC}  ${DIM}Coding effort:${NC}     %s days ${DIM}(%s)${NC}\n" "$coding_effort" "$(days_to_hm "$coding_effort")"
    if [ "$doc_level" != "None" ]; then
        printf "  ${CYAN}${BOX_V}${NC}  ${DIM}+ Documentation:${NC}   +%s days ${DIM}(%s — %s)${NC}\n" "$doc_effort_days" "$(days_to_hm "$doc_effort_days")" "$doc_level"
    fi
    if [ "$ai_level" != "None" ]; then
        printf "  ${CYAN}${BOX_V}${NC}  ${DIM}+ AI overhead:${NC}     +%s days ${DIM}(%s — RE/prompts/review)${NC}\n" "$ai_overhead_days" "$(days_to_hm "$ai_overhead_days")"
    fi

    if [ "$floored" = true ]; then
        printf "  ${CYAN}${BOX_V}${NC}  ${YELLOW}${ARROW} Minimum floor applied (%s days)${NC}\n" "$MIN_EFFORT_DAYS"
    fi

    printf "  ${CYAN}${BOX_ML}"
    printf '%0.s'"$BOX_H" $(seq 1 58)
    printf "${NC}\n"

    printf "  ${CYAN}${BOX_V}${NC} ${BOLD}${WHITE}${STAR} FINAL ESTIMATE${NC}\n"
    printf "  ${CYAN}${BOX_V}${NC}\n"
    printf "  ${CYAN}${BOX_V}${NC}    ${BOLD}${GREEN}%s days${NC}  ${DIM}|${NC}  ${BOLD}${GREEN}%s hours %s minutes${NC}\n" \
        "$final_effort" "$full_hours" "$minutes"
    printf "  ${CYAN}${BOX_V}${NC}\n"

    printf "  ${CYAN}${BOX_BL}"
    printf '%0.s'"$BOX_H" $(seq 1 58)
    printf "${NC}\n"

    # Factor summary table
    echo ""
    printf "  ${DIM}Factor Breakdown:${NC}\n"
    printf "  ${DIM}├── Base effort:${NC}    %s days ${DIM}(%s)${NC}\n" "$base_effort" "$(days_to_hm "$base_effort")"
    printf "  ${DIM}├── × Complexity:${NC}   %s (%s)\n" "$complexity_factor" "$selection_type"
    printf "  ${DIM}├── × Familiarity:${NC}  %s\n" "$familiarity_factor"
    printf "  ${DIM}├── × Coupling:${NC}     %s\n" "$coupling_factor"
    printf "  ${DIM}├── × Churn:${NC}        %s\n" "$churn_factor"
    printf "  ${DIM}├── × Testing:${NC}      %s\n" "$testing_factor"
    if [ "$ai_level" != "None" ]; then
        printf "  ${DIM}├── × AI reduction:${NC} %s (%s)\n" "$ai_coding_factor" "$ai_level"
    fi
    printf "  ${DIM}├── = Coding:${NC}       %s days ${DIM}(%s)${NC}\n" "$coding_effort" "$(days_to_hm "$coding_effort")"
    if [ "$doc_level" != "None" ]; then
        printf "  ${DIM}├── + Documentation:${NC} %s days ${DIM}(%s — %s)${NC}\n" "$doc_effort_days" "$(days_to_hm "$doc_effort_days")" "$doc_level"
    fi
    if [ "$ai_level" != "None" ]; then
        printf "  ${DIM}├── + AI overhead:${NC}  %s days ${DIM}(%s)${NC}\n" "$ai_overhead_days" "$(days_to_hm "$ai_overhead_days")"
    fi
    printf "  ${DIM}└── ${BOLD}= Total:${NC}       ${BOLD}%s days${NC} ${DIM}(%s h %s min)${NC}\n" "$final_effort" "$full_hours" "$minutes"

    # Log to history for calibration
    log_effort_history "$path" "$total_loc" "$selection_type" "$final_effort" \
        "$coupling_factor" "$churn_factor" "$testing_factor" "$complexity_factor" \
        "$base_effort" "$total_hours" "$ai_coding_factor" "$ai_level" \
        "$ai_overhead_days" "$doc_level" "$doc_effort_days" "$coding_effort" \
        "$familiarity_factor"

    echo ""
    printf "  ${DIM}${CHECK} Logged to ${UNDERLINE}%s${NC}\n" "$EFFORT_HISTORY_FILE"
}

# Function to process a path (file or directory)
process_path() {
    local path="$1"
    local path_name=$(basename "$path")

    if [ ! -e "$path" ]; then
        printf "  ${RED}Error: '%s' does not exist${NC}\n" "$path"
        return 1
    fi

    # Resolve git branch from the target path's repository
    local git_dir
    if [ -d "$path" ]; then
        git_dir="$path"
    else
        git_dir=$(dirname "$path")
    fi
    local target_branch
    target_branch=$(git -C "$git_dir" rev-parse --abbrev-ref HEAD 2>/dev/null)

    if [ "$detailed_mode" = true ]; then
        if [ -d "$path" ]; then
            box_header "Directory: $path_name"
            [ -n "$target_branch" ] && printf "  ${DIM}Branch:${NC} ${CYAN}%s${NC}\n" "$target_branch"
            while IFS= read -r -d '' file; do
                calculate_single_file "$file"
            done < <(eval find "$path" -type f $FILE_EXTENSIONS -print0)
        else
            calculate_single_file "$path"
        fi
    else
        box_header "$path_name"
        [ -n "$target_branch" ] && printf "  ${DIM}Branch:${NC} ${CYAN}%s${NC}\n" "$target_branch"
        calculate_effort "$path"
        echo ""
    fi
}

# Check if any paths are provided
if [ $# -eq 0 ]; then
    print_usage
fi

# Banner
echo ""
printf "  ${BOLD}${CYAN}╔══════════════════════════════════════${NC}\n"
printf "  ${BOLD}${CYAN}║  ${WHITE}${STAR} Effort Calculator v3.0 ${STAR}${NC}\n"
printf "  ${BOLD}${CYAN}╚══════════════════════════════════════${NC}\n"
printf "  ${DIM}$(date '+%Y-%m-%d %H:%M:%S')${NC}\n"

# Process each provided path
total_paths=$#
current_path=0

for path in "$@"; do
    ((current_path++))
    echo ""
    printf "  ${DIM}[%d/%d]${NC} ${BOLD}Processing:${NC} %s\n" "$current_path" "$total_paths" "$path"
    process_path "$path"
done

# Print final summary
echo ""
hr "═"
printf "  ${GREEN}${CHECK}${NC} ${BOLD}Analysis complete!${NC} Processed ${WHITE}%d${NC} path(s)\n" "$total_paths"
printf "  ${DIM}History: %s${NC}\n" "$EFFORT_HISTORY_FILE"
hr "═"
echo ""
