<?php
/*
 * Small script to create a proper changelog from GIT log output
 * Copyright (C) 2007 The LimeSurvey Project Team / Carsten Schmitz
 * All rights reserved.
 * License: GNU/GPL License v2 or later, see LICENSE.php
 * LimeSurvey is free software. This version may have been modified pursuant
 * to the GNU General Public License, and as distributed it includes or
 * is derivative of works licensed under the GNU General Public License or
 * other free or open source software licenses.
 * See COPYRIGHT.php for copyright notices and details.
 *
 */
$aStrings=file("php://stdin",FILE_SKIP_EMPTY_LINES);
$sAuthor='';
foreach ($aStrings as $sString)
{
  $sString=trim($sString);
  $sString=str_replace('#0','#',$sString);
  if (strpos($sString,'commit')===0 || strpos($sString,'Dev')===0 || strpos($sString,'Date')===0 || $sString=='') continue;
  if (strpos($sString,'Author')===0) {
    $sAuthor=substr($sString,8,strpos($sString,'<')-9);
    continue;
  }
  if (strpos($sString,'Updated translation')===0)
  {
    echo '#'.$sString."\n";
  }
  else
  {
    echo '-'.$sString." ($sAuthor)\n";
  }
}

 ?>
