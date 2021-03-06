using HTTPClient.HTTPC
#using Dates
using Gumbo

# =====================================================================
function fetchHistoricalData(sym::String, fromDate::Dates.Date, 
                             toDate=Dates.today()::Dates.Date, freq="d")
    
    fromY = Dates.year(fromDate);
    fromM = Dates.month(fromDate);
    fromD = Dates.day(fromDate);
    
    toY = Dates.year(toDate);
    toM = Dates.month(toDate);
    toD = Dates.day(toDate);
    
    url1 = "http://ichart.yahoo.com/table.csv?s=$sym&a=$(fromM-1)&b=$(fromD)"
    url2 = "&c=$(fromY)&d=$(toM-1)&e=$(toD)&f=$(toY)&g=$freq&ignore=.csv"
    url = "$url1$url2"

    page = HTTPC.get(url);
    text = String(page.body.data)
    
    if (text[1] == '<')
        error("Bad historical data pull for $sym")
    end
    
    table = readdlm(IOBuffer(text), ',', Any)

    HD = HistoricalData(sym, [Dates.Date(s) for s in table[end:-1:2,1]],
                        float64(table[end:-1:2,2]),
                        float64(table[end:-1:2,3]),
                        float64(table[end:-1:2,4]),
                        float64(table[end:-1:2,5]),
                        float64(table[end:-1:2,6]),
                        float64(table[end:-1:2,7]))
    
    return HD
end

# =====================================================================
function fetchQuotes(syms, props)
    urlbase = "http://download.finance.yahoo.com/d/quotes.csv?s="
    if (isa(syms, Array))
        symspart = "";
        for i=1:length(syms)-1
            symspart = "$symspart$(syms[i]),"
        end
        symspart = "$symspart$(syms[length(syms)])"
    else
        symspart = syms;
    end
    
    if (isa(props, Array))
        propspart = "";
        for i=1:length(props)
            propspart = "$propspart$(props[i])"
        end
    else
        propspart = props
    end
    
    url = "$urlbase$symspart&f=$propspart&e=.csv"

    page = HTTPC.get(url)
    text = String(page.body.data)
    if (text[1] == '<')
        error("Bad quotes pull")
    end
    
    table = readdlm(IOBuffer(text), ',', Any)
    
    return table;
end


# =====================================================================
function fetchSectors(sortBy::String = "coname", sortDir::String = "u")
    
    url = "http://biz.yahoo.com/p/csv/s_$sortBy$sortDir.csv"
    
    page = HTTPC.get(url)
    text = String(page.body.data)
    if (text[1] == '<')
        error("Bad sector pull")
    end
    
    table = readdlm(IOBuffer(text), ',', Any);
    
    # table from Yahoo is "null terminated", so return all but last line
    return table[1:end-1,:];
end

# =====================================================================
function fetchIndustries(sectorNum, sortBy::String = "coname", sortDir::String = "u")
    
    url = "http://biz.yahoo.com/p/csv/$(sectorNum)$sortBy$sortDir.csv";
    println(url)
    page = HTTPC.get(url)
    text = String(page.body.data)
    if (text[1] == '<')
        error("Bad Industries pull")
    end

    table = readdlm(IOBuffer(text), ',', Any);
    
    return table[1:end-1,:];
end

# =====================================================================
function fetchCompanies(industryNum, sortBy::String = "coname", sortDir::String = "u")
    
    url = "http://biz.yahoo.com/p/csv/$(industryNum)$sortBy$sortDir.csv";
    println(url)
    page = HTTPC.get(url)
    text = String(page.body.data)
    if (text[1] == '<')
        error("Bad Companies pull")
    end

    table = readdlm(IOBuffer(text), ',', Any);
    
    return table[1:end-1,:];
end

# =====================================================================
function fetchRSS(symbol::String, locale::String = "en-us")
    
    url = "http://feeds.finance.yahoo.com/rss/2.0/headline?s=$symbol&region=$(locale[4:end])&lang=$locale"

    page = HTTPC.get(url)
    text = String(page.body.data)
    
    # parse html with gumbo package
    doc = parsehtml(text)
    
    # prepare empty Array{Any,1} for return
    articles = []
    
    # Parse returned html document
    chan = doc.root.children[2].children[1].children[1]
    for ch in chan.children
        if(isa(ch, Gumbo.HTMLElement{:item}))
            # This condition handles the event where no page is found
            if (isa(ch.children[1],Gumbo.HTMLElement{:title}) && isa(ch.children[3],HTMLText))
                title = ch.children[1].children[1].text
                link = ch.children[3].text
                push!(articles, (title, link))
            end
        end
    end
    
    return articles;
end
