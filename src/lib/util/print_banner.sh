print_banner() {
  local graphic_b64="ICAgICAgIF9fX19fXwogICAgICAvX19fX19fXAogICAgL19fX19fX19fX19cCiAgIHxfX19fX19fX19fX198CiAgL19fX19fX19fX19fX19fXAogIHxfX19fX19fX19fX19fX3wKIC9fX19fX19fX19fX19fX19fXAogfF9fX19fX1/ilojilohfX19fX19ffAogfF9fX19fX1/ilojilohfX19fX19ffAogXyAgXyBfX19fX18gICBfX19fXwp8IHx8IHxfIF9cXCBcIC8gLyBfX3wKfCBfXyB8fCB8IFxcIFYgL3wgX3wKfF98fF98X19ffCBcXF8vIHxfX198Cg=="

  local tagline="A single-pane toolbox for Docker Swarm clusters"
  base64 -d <<< "$graphic_b64"
  if [[ "${1,,}" == "tagline" ]]; then
    echo
    echo "$tagline"
  fi
}