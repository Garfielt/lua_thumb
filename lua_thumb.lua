-- config
local backend_server = "http://your_domain_here";
local convert_bin = "/usr/bin/convert";
local image_types = {"jpg", "bmp", "gif", "png", "webp"};
local image_default_quality = "75%";
local image_sizes = { "500x500", "320x320", "200x200", "160x160", "80x80"};


-- parse uri
function parseUri(uri)
    local _, _, name, size, ext = string.find(uri, "(.+)_(%d+x%d+).(%w+)$");
    if name ~= nil then
        ext = name:match(".+%.(%w+)$");
    else
        ext = uri:match(".+%.(%w+)$");
    end
    if name and size then
        return name, size, ext;
    else
        return uri, nil, ext;
    end
end

-- is file exists
function fileExists(name)
    local f = io.open(name, "r");
    if f ~= nil then
        io.close(f);
        return true;
    else
        return false;
    end
end

-- is dir
function is_dir(filePath)
    if type(filePath) ~= "string" then return false end

    local response = os.execute("cd " .. filePath);
    if response == 0 then
        return true;
    end
    return false;
end

-- is image
function is_image(file_extension)
    for _, value in pairs(image_types) do
        if value == file_extension then
            return true;
        end
    end
    return false;
end

-- get file's dir
function fileDir(filename)
    return string.match(filename, "(.+)/[^/]*%.%w+$");
end

-- check size exist
function sizeExists(size)
    for _, value in pairs(image_sizes) do
        if value == size then
            return true;
        end
    end
    return false;
end

local original_url, resize, extension = parseUri(ngx.var.uri);
local local_file = ngx.var.document_root .. original_url;
-- ngx.log(ngx.ERR, local_file);

-- ../ safe check
local dotcheck = string.find(original_url, '%.%./')
if dotcheck == nil then
    -- get original file
    if fileExists(local_file) == false then
        local local_dir = fileDir(local_file);
        if not is_dir(local_dir) then
            os.execute("mkdir -p " .. local_dir);
        end
        local local_ob_file = local_file .. ".o." .. extension;
        local command = string.format("wget -P " .. local_dir .. " \"" .. backend_server .. original_url .. "\" -O " .. local_ob_file);
        os.execute(command);
        if is_image(extension) then
            command = table.concat({
                convert_bin,
                "-strip -quality",
                image_default_quality,
                local_ob_file,
                local_file,
            }, " ");
            os.execute(command);
            command = string.format("rm -f " .. local_ob_file);
        else
            command = string.format("mv " .. local_ob_file .. " " .. local_file);
        end
        os.execute(command);
    end

    -- resize images if
    if is_image(extension) then
        if sizeExists(resize) then
            command = table.concat({
                convert_bin,
                "-strip -resize",
                "\"" .. resize .. ">\"",
                local_file,
                ngx.var.document_root .. ngx.var.uri,
            }, " ");
            os.execute(command);
        end
    else
        ngx.exec(original_url);
    end
else
    ngx.exit(404);
end