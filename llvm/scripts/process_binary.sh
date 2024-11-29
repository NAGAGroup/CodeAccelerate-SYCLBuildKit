#!/bin/bash

binary="$1"

if file "$binary" | grep -q "ELF"; then
  # Get the current RPATH
  current_rpath=$(patchelf --print-rpath "$binary" 2>/dev/null)

  # If there's no RPATH, skip
  if [[ -n "$current_rpath" ]]; then
    # Remove $PREFIX from the RPATH by replacing it with ":"
    new_rpath=$(echo "$current_rpath" | sed "s|$PREFIX/lib||g" | sed 's|::|:|g' | sed 's|^:||;s|:$||')

    # If the new RPATH is empty, set it explicitly
    if [[ -z "$new_rpath" ]]; then
      new_rpath="\$ORIGIN"
    fi

    # Update the binary's RPATH
    echo -n "  Updating RPATH for $binary..."
    patchelf_cmd="'$BUILD_PREFIX'/bin/patchelf"
    cache_dir="$PROJECT_ROOT/.cache/patch-rpaths"
    enable_sudo="$cache_dir/enable_sudo"
    if [ -f "$enable_sudo" ]; then
      patchelf_cmd="sudo $patchelf_cmd"
    fi
    if ! bash -c "$patchelf_cmd --set-rpath '$new_rpath' '$binary'"; then
      echo "Permission denied for $binary."

      # Ask user if they want to retry with sudo
      read -p "Do you want to patching process using sudo? [y/N] " choice
      if [[ "$choice" =~ ^[Yy]$ ]]; then
        mkdir -p "$cache_dir"
        touch "$enable_sudo"
        bash -c "sudo '$BUILD_PREFIX'/bin/patchelf --set-rpath '$new_rpath' '$binary'"
        if [[ $? -eq 0 ]]; then
          echo "Successfully updated RPATH for $binary with sudo."
        else
          echo "Failed to update RPATH for $binary even with sudo."
        fi
      else
        echo "Skipping $binary."
      fi
    else
      echo "Done."
    fi
  fi
fi
