<?php
//Revert all features
echo "Config import start...\n";
passthru('drush config-import -y');
echo "Config import complete.\n";
//Clear all cache
echo "Clearing cache.\n";
passthru('drush cr');
echo "Clearing cache complete.\n";