from lussi.stackoverflow import *
from lussi.ziprecruiter import *


nogit_data_dir = "622data_nogit"

## to build, uncomment this line.
# build_stack(data_dir=nogit_data_dir)
# build_zip(data_dir=nogit_data_dir)

# ## to load, use these.
# # raw_stack  = load_stack(data_dir = nogit_data_dir, stack_type=StackType.RAW)
# # wide_stack = load_stack(data_dir = nogit_data_dir, stack_type=StackType.WIDE)
# ziprecruiter = load_zip(data_dir = nogit_data_dir)


# # print(raw_stack.head())
# # print(wide_stack.head())
# print(ziprecruiter.head())