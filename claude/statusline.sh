
################################################################################

}

format_duration() {
}

}

format_token() {
}


################################################################################

get_model_field() {
}

get_effort_field() {
    [ -z "$effort" ] && [ -z "$think" ] && return
        case "$effort" in
            high)  ec="$yellow" ;;
            xhigh) ec="$red" ;;
            max)   ec="$red" ;;
            *)     ec="$reset" ;;
        esac
    fi
}

    fi
}

get_token_usage() {
}

}

get_rate_limit_field() {
    fi
    fi
}

get_version_field() {
}

################################################################################


segments=(
    "$(get_dir_field)"
    "$(get_model_field)"
    "$(get_effort_field)"
    "$(get_rate_limit_field)"
    "$(get_version_field)"
)
done
