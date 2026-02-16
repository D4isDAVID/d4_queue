local waitingEmojiIndex = 1

function Utils.getWaitingEmoji()
    local waitingEmojiTable = Convars.waitingEmoji()

    waitingEmojiIndex += 1
    if waitingEmojiIndex > #waitingEmojiTable then
        waitingEmojiIndex = 1
    end

    return waitingEmojiTable[waitingEmojiIndex]
end
