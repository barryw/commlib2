build:
	@docker run -v ${PWD}:/code barrywalker/kickassembler:latest -time -bytedump /code/commlib2.asm
