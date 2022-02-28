define-command symflower -params .. -docstring %{symflower [<args>...]: generate unit tests

Results are summarized in the *symflower* scratch buffer.
Any arguments are forwarded to the 'symflower' command.
} %{ evaluate-commands %sh{
	output=$(mktemp -d "${TMPDIR:-/tmp}"/symflower-kakoune.XXXXXXXX)/fifo
	mkfifo ${output}
	(
		(
			printf %s\\n "\$ symflower $*"
			symflower "$@"
		) > ${output} 2>&1 &
	) >/dev/null 2>&1 </dev/null

	printf %s\\n "evaluate-commands -draft %{
		edit! -fifo ${output} -scroll *symflower*
		hook -always -once buffer BufCloseFifo .* %{ nop %sh{ rm -r $(dirname ${output}) } }
	}"
}}

define-command symflower-unit-tests -params .. -docstring %{symflower-unit-tests [<args>...]: generate unit tests for the functions at the main selection

Any arguments are forwarded to the 'symflower unit-tests' command.
} %{
	write
	evaluate-commands %sh{
		quote() {
			for arg; do {
				printf " '%s'" "$(printf %s "$arg" | sed "s/'/''/g")"
			} done
		}
		workspace=${kak_buffile%/*}
		cursor_location=$(echo "${kak_selection_desc}" | sed 's/[.]/:/g; s/,/-/')
		quote symflower unit-tests --workspace "${workspace}" "${kak_buffile#$workspace/}:${cursor_location}" "$@"
		quote "${kak_buffile#$workspace/}"
		echo
		echo "try symflower-alternative-file"
	}
}

define-command symflower-unit-test-skeletons -params .. -docstring %{symflower-unit-test-skeletons [<args>...]: generate unit test skeletons for the functions at the main selection

Any arguments are forwarded to the 'symflower unit-test-skeletons' command.
} %{
	write
	evaluate-commands %sh{
		quote() {
			for arg; do {
				printf " '%s'" "$(printf %s "$arg" | sed "s/'/''/g")"
			} done
		}
		workspace=${kak_buffile%/*}
		cursor_location=$(echo "${kak_selection_desc}" | sed 's/[.]/:/g; s/,/-/')
		output=$(symflower unit-test-skeletons --workspace "${workspace}" "${kak_buffile#$workspace/}:${cursor_location}" "$@" 2>&1)
		location=$(printf %s "$output" | sed -nE '/^[^:]+: (generated|updated) test at (.*)/{s/^.* at (.*:[0-9]+:[0-9]+)$/\1/;p}')
		filename=$(printf %s "$location" | sed -E 's/^(.*):[0-9]+:[0-9]+$/\1/')
		coordinates=$(printf %s "$location" | sed -E 's/^.*:([0-9]+):([0-9]+)$/\1 \2/')
		printf "edit! -existing -- %s $coordinates" "$(quote "$workspace/$filename")"
	}
}

define-command symflower-alternative-file -docstring 'Jump to the alternate file (implementation ↔ Symflower test)' %{ evaluate-commands %sh{
	case "$kak_buffile" in # REMARK Cases are ordered to match specific extensions first and general language files last.
	(*_symflower_test.go)
		altfile=${kak_buffile%_symflower_test.go}.go
		test ! -f "$altfile" && echo "fail 'implementation file not found'" && exit
		;;
	(*_test.go)
		altfile=${kak_buffile%_test.go}.go
		test ! -f "$altfile" && echo "fail 'implementation file not found'" && exit
		;;
	(*.go)
		altfile=${kak_buffile%.go}_symflower_test.go
		test ! -f "$altfile" && echo "fail 'Symflower test file not found'" && exit
		;;
	(*SymflowerTest.java)
		altfile=${kak_buffile%SymflowerTest.java}.java
		test ! -f "$altfile" && echo "fail 'implementation file not found'" && exit
		;;
	(*.java)
		altfile=${kak_buffile%.java}SymflowerTest.java
		test ! -f "$altfile" && echo "fail 'Symflower test file not found'" && exit
		;;
	(*)
		echo "fail 'alternative file not found'" && exit
		;;
	esac
	printf "edit -- '%s'" "$(printf %s "$altfile" | sed "s/'/''/g")"
}}
