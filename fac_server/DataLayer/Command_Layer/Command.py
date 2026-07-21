from dataclasses import dataclass

@dataclass
class LS_Command():
    chan:int
    comm:str
    addr: list[str]

#커맨드 종합
def separate_addr(addr_list):
    comm_list = []
    for chan, adr in addr_list.items():
        if adr[0]:
            comm_list.extend(separate_chan_addr(adr[0], chan))
        if adr[1]:
            comm_list.extend(separate_chan_addr(adr[1], chan))
    print(comm_list)
    return comm_list

#단일 채널의 커맨드 리스트 반환
def separate_chan_addr(ls, chan):
    adr_stack = []
    hex_list = []
    for i in ls:
        adr_stack.append(i)
        if len(adr_stack) == 16:
            hex_list.append(makecommand(adr_stack, chan))
            adr_stack = []
    
    if adr_stack:
        hex_list.append(makecommand(adr_stack, chan))
    return hex_list

#단일 포맷 반환
def makecommand(addrs, chan):
    len_addrs = [f"{len(x):02d}{x}" for x in addrs]

    return LS_Command(
        chan = chan,
        comm=f"\x05{chan:02d}RSS{len(len_addrs):02x}{"".join(len_addrs)}\x04",
        addr=addrs
    )
