#!/bin/bash -e

git grep -l -E "(\/\/  Copyright © )([0-9]*(\s*-\s*[0-9]+){0,1})( Wix\. All rights reserved\.)" | while read -r FILE ; do
	YEAR=`date +'%Y'`
	sed -i '' -E "s/(\/\/  Copyright © )([0-9]*(\s*-\s*[0-9]+){0,1})( Wix\. All rights reserved\.)/\12017-$YEAR\4/" "${FILE}"
done