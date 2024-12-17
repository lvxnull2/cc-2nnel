local URL = "https://raw.githubusercontent.com/lvxnull2/cc-2nnel/refs/heads/main/"

local files = {
  miner = {
    "startup.lua",
  },
  cnc = {
    "2nnel.lua",
  }
}

local function download_file(url, path)
  local f = fs.open(path, "w")
  local r = http.get(url)
  f.write(r.readAll())
  f.close()
  r.close()
end

local function dl(files, ...)
  local extras = {"", ...}
  files[""] = files

  for _, e in ipairs(extras) do
    for _, p in ipairs(files[e]) do
      print("Downloading " .. p)
      download_file(("%s/%s/%s"):format(URL, e, p), p)
    end
  end
end

if turtle then
  dl(files, "miner")
else
  dl(files, "cnc")
end
print("Download complete")
