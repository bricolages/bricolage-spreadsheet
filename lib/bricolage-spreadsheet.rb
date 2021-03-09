require 'bricolage/jobclass'
require 'pathname'

jobclass_path = Pathname(__dir__).realpath.parent.cleanpath + 'jobclass'
Bricolage::JobClass.add_load_path jobclass_path
