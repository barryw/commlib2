build:
	@docker run -v ${PWD}:/code barrywalker/kickassembler:latest -time -bytedump /code/commlib2.asm

test:
	@docker run -v ${PWD}:/code barrywalker/kickassembler:latest -time -bytedump /code/test.asm

disk: build
	@c1541 -format commlib2,cl d64 commlib2.d64 -attach commlib2.d64 -write commlib2.prg commlib2
