(async () => {

    const src = chrome.extension.getURL('util/extended-prototype.js');
    const injectScript = await import(src);
    injectScript.extendHTMLElementProtoType();
    injectScript.extendStringProtoType();

    const srcBoard = chrome.extension.getURL('components/board.js');
    const boardModuleBuilder = await import(srcBoard);
    const Board = boardModuleBuilder.Board;

    const debounceSrc = chrome.extension.getURL('util/debounce.js');
    const debounceScript = await import(debounceSrc);

    let HISTORY_ITEM_TEMPLATE = '<div class="title">{title}</div><div class="description">{description}</div>';
    const RESPONSE_STATUS = {
        OK: 'OK',
        FAILED: 'FAILED',
    };

    function init() {
        chrome.storage.sync.get(['token', 'userInfo', 'history', 'selectedNode', 'selectedBoard', 'selectedTab'], function (storage) {
            if (storage.token) {
                selectTab(storage.selectedTab)
                hideUnauthSection();
                setupProfile(storage.userInfo);
                generateHistory(storage.history);
                generateSelectedNode(storage.selectedNode);
                generateBoards();
                generateSelectedBoard(storage.selectedBoard);
            } else {
                hideAuthSection();
            }
        });
    }

    init();

    function hideUnauthSection() {
        document.querySelector('.un-auth').style.display = 'none';
        document.querySelector('.auth').style.display = 'block';
    }

    function hideAuthSection() {
        document.querySelector('.un-auth').style.display = 'block';
        document.querySelector('.auth').style.display = 'none';
    }

    function clearBoards() {
        document.querySelector('.board').innerHTML = '';
    }

    function clearHistory() {
        document.querySelector('.history').innerHTML = '';
    }

    function setupProfile(userInfo) {
        document.querySelector('.profile-container').innerHTML = '<img src="' + userInfo.picture + '" />'
        document.querySelector('.name').innerHTML = userInfo.name;
        document.querySelector('.email').innerHTML = userInfo.email;
    }

    selectBoard = (board) => {
        chrome.storage.sync.set({
            selectedBoard: {
                id: board.id,
                title: board.title,
                uniquename: board.uniquename
            }
        });
        generateSelectedBoard(board);
    }

    selectNode = (node) => {
        chrome.storage.sync.set({
            selectedNode: node
        });
        generateSelectedNode(node);
    }

    selectTab = (className) => {
        if (!className) {
            className = 'board';
        }
        const children = document.querySelector('.body').children;
        for (let i = 0; i < children.length; i++) {
            children[i].style.display = 'none';
            if (children[i].className.split(' ').indexOf(className) !== -1) {
                children[i].style.display = 'block';
            }
        }
        document.querySelectorAll('li[class^="tab-"]').forEach((el) => {
            // remove tab selected class
            const classNames = el.className.split(' ');
            if (classNames.indexOf('selected') !== -1) {
                classNames.splice(classNames.indexOf('selected'), 1)
                const newClassName = classNames.join(' ');
                el.className = newClassName;
            }
            if (el.className.split(' ').indexOf('tab-' + className) !== -1) {
                el.className = el.className + ' selected';
            }
        });
        chrome.storage.sync.set({
            selectedTab: className
        });
    }

    generateSelectedBoard = (selectedBoard) => {
        const selectedBoardDom = document.querySelector('.selected-board');
        if (selectedBoard && selectedBoardDom) {
            selectedBoardDom.querySelector('.content').innerHTML = selectedBoard.title;
        }
    }

    createBoardItem = (data) => {
        const board = new Board(data, (e) => {
            selectBoard(e.currentTarget.dataset);
        }, (e) => {
            const boardElement = e.currentTarget.parentElement.parentElement;
            removeBoard({
                uniquename: boardElement.dataset.uniquename
            }, board);
        }, (e) => {
            const boardElement = e.currentTarget.parentElement.parentElement.parentElement;
            const isPublic = !(boardElement.dataset.is_public === 'true');
            boardElement.dataset.is_public = isPublic;
            changeBoardPermissionDebounce({
                ...boardElement.dataset,
                is_public: isPublic,
            }, board);
        });
        return board;
    }

    generateBoards = () => {
        chrome.runtime.sendMessage({
            controller: 'board',
            action: 'get'
        }, function (resp) {
            if (resp.status === RESPONSE_STATUS.OK) {
                let boardDom = document.querySelector('.board');
                for (let i = 0; i < resp.data.boards.length; i++) {
                    const board = createBoardItem(resp.data.boards[i]);
                    boardDom.appendChild(board.element);
                }
            } else {
                alert(resp.data.errorMsg);
            }
        });
    }

    function generateHistory(history) {
        if (!history) {
            return;
        }
        for (var i = 0; i < history.length; i++) {
            const historyItem = document.createElement('div');
            historyItem.dataset = {
                id: history[i].id
            }
            historyItem.className = 'item';
            historyItem.innerHTML = HISTORY_ITEM_TEMPLATE.replace(/{title}/gi, history[i].title)
                .replace(/{description}/gi, history[i].description)
                .replace(/{id}/gi, history[i].id)
            document.querySelector('.history').appendChild(historyItem);
            historyItem.addEventListener('click', (e) => {
                const node = {
                    id: e.currentTarget.dataset.id,
                    title: e.currentTarget.querySelector('.title').innerHTML,
                    description: e.currentTarget.querySelector('.description').innerHTML
                };
                selectNode(node);
            });
        }
    }

    function generateSelectedNode(node) {
        if (node) {
            document.querySelector('.selected-node .content').innerHTML = node.title;
        }
    }

    clearSelectedNode = () => {
        document.querySelector('.selected-node .content').innerHTML = '';
        chrome.storage.sync.set({
            selectedNode: null
        });
    }

    clearSelectedBoard = () => {
        document.querySelector('.selected-board .content').innerHTML = '';
        chrome.storage.sync.set({
            selectedBoard: null
        });
    }

    postBoard = (formData) => {
        chrome.runtime.sendMessage({
            controller: 'board',
            action: 'post',
            data: formData
        }, function (resp) {
            if (resp.status === RESPONSE_STATUS.OK) {
                document.querySelector('.board-form').clearForm();
                const board = createBoardItem(resp.data);
                document.querySelector('.board').prepend(board.element);
            } else {
                alert(resp.errorMsg);
            }
        });
    }

    changeBoardPermissionDebounce = debounceScript.debounce((formData, boardItem) => {
        changeBoardPermission(formData, boardItem);
    }, 1500);

    changeBoardPermission = (formData, boardItem) => {
        chrome.runtime.sendMessage({
            controller: 'board',
            action: 'patch',
            data: {
                ...formData,
                is_public: formData.is_public
            }
        }, async (resp) => {
            if (resp.status === RESPONSE_STATUS.OK) {
                boardItem.update(resp.data)
            } else {
                alert(resp.errorMsg);
            }
        });
    };

    removeBoard = (formData, boardItem) => {
        chrome.runtime.sendMessage({
            controller: 'board',
            action: 'delete',
            data: formData
        }, function (resp) {
            if (resp.status === RESPONSE_STATUS.OK) {
                boardItem.element.parentElement.removeChild(boardItem.element);
            } else {
                alert(resp.errorMsg);
            }
        })
    }

    /**
     * Event Listener
     */

    document.querySelector('.selected-node').addEventListener('click', clearSelectedNode);
    document.querySelector('.selected-board').addEventListener('click', clearSelectedBoard);
    document.querySelector('.auth-google').addEventListener('click', function () {
        chrome.runtime.sendMessage({
            controller: 'auth'
        }, (resp) => {
            if (resp.status === RESPONSE_STATUS.OK) {
                init();
            } else {
                alert(resp.data.errorMsg);
            }
        });
    });

    document.querySelector('.btn-logout').addEventListener('click', () => {
        chrome.storage.sync.set({
            token: null,
            userInfo: null,
            history: null,
            selectedNode: null
        }, () => {
            hideAuthSection();
            clearHistory();
            clearBoards();
        });
    });

    document.querySelectorAll('.tab-board,.tab-history').forEach((el) => {
        el.addEventListener('click', (e) => {
            const className = e.currentTarget.className.replace(/tab\-/gi, '');
            const classes = className.split(' ')
            if (classes.indexOf('selected') !== -1) {
                classes.splice(classes.indexOf('selected'), 1);
                showClassName = classes.join(' ');
            } else {
                showClassName = classes.join(' ');
            }
            selectTab(showClassName);
        })
    });

    document.querySelector('.tab-board .expand').addEventListener('click', (e) => {
        const boardForm = document.querySelector('.board-form');
        if (boardForm.classExists('hide')) {
            boardForm.removeClass('hide');
            boardForm.querySelectorAll('input')[0].focus();
        } else {
            boardForm.addClass('hide');
        }
    }, false);

    document.querySelectorAll('.board-form input').forEach((el) => {
        el.addEventListener('keyup', (e) => {
            if (e.keyCode === 13) {
                const formData = document.querySelector('.board-form').collectFormData();
                postBoard(formData);
            }
        });
    })

    document.querySelector('.board-form .add').addEventListener('click', (e) => {
        const formData = document.querySelector('.board-form').collectFormData();
        postBoard(formData);
    });
})();