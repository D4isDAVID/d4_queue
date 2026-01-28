API.thread = {}

local ONE_SECOND = 1000

local running = false

local function thread()
    print('Queue thread has started')

    while not API.queue.wait() do
        Wait(ONE_SECOND)
    end

    running = false
    print('Queue thread has ended')
end

function API.thread.start()
    if running then return end
    running = true
    Citizen.CreateThread(thread)
end
