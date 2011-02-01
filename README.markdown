What is NazScrooge?
===================

NazScrooge is a virtual lockbox. It allows you to set money aside to save. 

Features
========

You have a few different ways to save and you can mix and match them as you
see fit.

  1. You can manually deposit and withdraw money by using the /scr deposit
  goldamount and /scr withdraw goldamount commands.
  
  2. You can set a target gold amount you're saving towards. This can be
  combined with any of the other &amp;quot;auto save&amp;quot; options, or you
  can manually deposit into your lockbox until you hit your goal.
  
  3. You can automatically set aside a percentage of your earnings. Ie: If you
  make 10 silver off of a mob and have it set to save 50%, you'll only notice
  the money in your bags go up by 5s, the other 5s goes into the lockbox.
  
  4. You can set a minimum amount you want saved in your lockbox. If you set a
  minimum number, you will deposit 100% of everything you make until you hit
  that number. Everything after that will be based on your other settings,
  such as percent saved, etc. The only way to go below this minimum is by
  manually withdrawing money. However, if you do this you have to spend it
  before you make any more money or it will correct itself to save the minimum
  amount you have selected. Ie: If you have 14g in your lockbox, have the
  minimum set for 10g, and /scr withdraw 10. That leaves you with 4g in the
  box. If you make ANY money in ANY way before spending the money you withdrew
  it will autodeposit 6g to make you hit the minimum amount. Only withdraw
  right before you spend with these options on.
  
  5. You can have all money after a certain amount go into the lockbox. Ie:
  You have the maximum set for 100g, and you make money that takes you over
  100g, it will autodeposit everything after 100g into the lockbox. Just like
  the minimum, you can /scr withdraw goldamount to go above what you have set
  for the max in order to spend it, but as soon as you make ANY money it will
  take all but 100g and put in into the lockbox.
  
  6. This addon has various options to select output. For example you can
  change if it displays text in the chat frame, SCT, Parrot, etc. See
  configuration options for details.
  
Commands
========

  * /scr (will display the GUI)
  * /scr withdraw goldamount (will withdraw money ignoring any settings you
    have)
  * /scr deposit goldamount (will deposit money ignoring any settings you
    have)
  * /scr display (shows amount in lockbox)
  * /scr help (lists all of the manual commands)

Localization
============

If anyone is willing to help localize this addon, please head over to
curseforge (or go to this page:
http://wow.curseforge.com/projects/nazscrooge/localization/ and submit
translations. I wish I could do it myself, but alas I only know english.

LDB Plugin
==========

To take advantage of the LDB plugin part of this addon, you need to have a
LibDataBroker display addon installed as well.

More information on LibDataBroker can be found on it's [wiki][]

  [wiki]: http://github.com/tekkub/libdatabroker-1-1/wikis