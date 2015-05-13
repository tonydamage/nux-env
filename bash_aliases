# Maven Aliases
alias mci="mvn clean install"
alias mvn-fastclean="find -name target -type d | xargs rm -rf"
# GIT and GITK Aliases
alias gitk-all="(git branch -l) | sed "s/^*//" | xargs gitk"

# alias analyse-java-name-conflict="find -iname *.java | grep -v package-info.java | grep -v yang-gen | grep -v target | sed "s/[\\.a-z0-9\\/\\-]*\\/\([\\\$a-zA-Z0-9]*\)\.java/\1/g" | sort | uniq -c | grep -v " 1 ""
# alias analyse-java-annotation=find -iname "*.java" | xargs grep "@$1" | sed "s/@$1\\(.*\\)/\\1/g"
