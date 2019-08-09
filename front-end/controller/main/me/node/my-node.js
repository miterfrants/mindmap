import {
    RouterController
} from '/mindnote/route/router-controller.js';

import {
    api
} from '/mindnote/service/api.v2.js';

import {
    RESPONSE_STATUS
} from '/mindnote/constants.js';

import {
    MindnoteError,
    MINDNOTE_ERROR_TYPE
} from '/mindnote/util/mindnote-error.js';

import {
    UI
} from '/mindnote/ui.js';

import {
    markdownit
} from '/mindnote/third-party/markdow-it/mdit.min.js';

import {
    MarkdownItAttrs
} from '/mindnote/third-party/markdow-it/markdown-it-attrs.browser.js';

import {
    Swissknife
} from '/mindnote/service/swissknife.js';

import LazyLoad from '/mindnote/third-party/lazyload/lazyload.esm.js';

export class MyNode extends RouterController {
    constructor(elHTML, parentController, args, context) {
        super(elHTML, parentController, args, context);
        this.node = null;
        this.board = null;
    }
    async init() {
        this._bindEvent();
    }
    async enter(args) {
        super.enter(args);
        this.node = null;
        this.board = null;
    }
    async render(withoutCache) {
        super.render();
        this.node = await this._getTargetNode(withoutCache);
        this.board = await this._getTargetBoard(withoutCache);
        this.elHTML.querySelector('.title').innerHTML = this.node.title;
        this.elHTML.querySelector('.content').innerHTML = markdownit()
            .use(MarkdownItAttrs, {
                allowedAttributes: ['data-height']
            })
            .render(this.node.description);
        UI.header.generateNavigation([{
            title: '我的分類',
            link: '/mindnote/users/me/boards/'
        }, {
            title: this.board.title,
            link: `/mindnote/users/me/boards/${this.args.boardId}/`
        }, {
            title: this.node.title
        }]);
        this._showOrHideHeader();
        this._lazyloadImage();
    }
    async postRender() {
        new LazyLoad({
            elements_selector: '.lazyload',
            callback_loaded: (el) => {
                el.removeClass('blur');
            },
            load_delay: 1000
        });
    }
    _lazyloadImage() {
        this.elHTML.querySelectorAll('.content img').forEach((img) => {
            const elImageContainer = document.createElement('span');
            elImageContainer.addClass('img-container');

            const elImageParent = img.parentElement;
            elImageParent.insertBefore(elImageContainer, img);
            elImageContainer.appendChild(img);

            const heightPercentage = img.dataset['height'];
            elImageContainer.style.paddingTop = heightPercentage;
            const questionMarkPosition = img.src.indexOf('?');
            const rotQueryKeyPosition = img.src.indexOf('rot', questionMarkPosition);
            const widthKeyPosition = img.src.indexOf('w=', questionMarkPosition);
            if (rotQueryKeyPosition === -1) {
                img.src += questionMarkPosition === -1 ? '?rot' : '&rot';
            }
            img.dataset['src'] = img.src + '&w=1000';
            img.addClass('lazyload');
            if (widthKeyPosition === -1) {
                img.src += '&w=10';
            }
            img.addClass('blur');
        });
    }
    _showOrHideHeader() {
        if (Swissknife.getQueryString('hide-header') === 'true') {
            document.querySelector('.header').addClass('hide');
        } else {
            document.querySelector('.header').removeClass('hide');
        }
    }

    async _getTargetNode(withoutCache) {
        const filterNode = this.args.nodes ? this.args.nodes.filter((node) => {
            return node.id === this.args.nodeId;
        }) : [];
        if (filterNode.length > 0) {
            return filterNode[0];
        } else {
            const resp = await api.authApiService.node.get({
                boardId: this.args.boardId,
                nodeId: this.args.nodeId,
                token: this.args.token
            }, null, withoutCache);
            if (resp.status === RESPONSE_STATUS.FAILED) {
                if (resp.httpStatus === 417) {
                    throw new MindnoteError(MINDNOTE_ERROR_TYPE.WARN, resp.data.errorMsg);
                } else {
                    throw new MindnoteError(MINDNOTE_ERROR_TYPE.ERROR, resp.data.errorMsg);
                }
            }
            return resp.data;
        }
    }
    async _bindEvent() {
        this.elHTML.querySelector('.btn-copy-shared-link').addEventListener('click', (e) => {
            if (e.currentTarget.classExists('disabled')) {
                return;
            }
            const button = e.currentTarget;
            Swissknife.copyText(window.location.origin + '/mindnote/boards/' + this.args.boardId + '/nodes/' + this.args.nodeId + '/');
            button.querySelector('span').innerHTML = '已複製';
            button.addClass('copied');
            setTimeout(() => {
                button.querySelector('span').innerHTML = '複製公開連結';
                button.removeClass('copied');
            }, 3000);
        });
    }
    async _getTargetBoard(withoutCache) {
        const resp = await api.authApiService.board.get({
            boardId: this.args.boardId,
            token: this.args.token
        }, null, withoutCache);
        if (resp.status === RESPONSE_STATUS.FAILED) {
            if (resp.httpStatus === 417) {
                throw new MindnoteError(MINDNOTE_ERROR_TYPE.WARN, resp.data.errorMsg);
            } else {
                throw new MindnoteError(MINDNOTE_ERROR_TYPE.ERROR, resp.data.errorMsg);
            }
        }
        return resp.data;
    }
}