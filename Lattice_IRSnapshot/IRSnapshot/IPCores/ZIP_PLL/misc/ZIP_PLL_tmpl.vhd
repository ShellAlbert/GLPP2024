component ZIP_PLL is
    port(
        ref_clk_i: in std_logic;
        rst_n_i: in std_logic;
        lock_o: out std_logic;
        outcore_o: out std_logic;
        outglobal_o: out std_logic
    );
end component;

__: ZIP_PLL port map(
    ref_clk_i=>,
    rst_n_i=>,
    lock_o=>,
    outcore_o=>,
    outglobal_o=>
);
