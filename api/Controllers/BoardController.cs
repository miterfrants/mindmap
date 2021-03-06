using System.Net;
using System.Collections.Generic;
using System;
using System.Linq;
using Microsoft.AspNetCore.Mvc;

using Mindnote.Models;
using Mindnote.Services;
using Mindnote.Constants;

namespace Mindnote.Controllers
{
    [Route("mindnote/api/v1/boards/")]
    [ApiController]
    public class BoardController : ControllerBase
    {
        private readonly MindnoteContext _context;
        private readonly MindnoteContextForView _contextForView;
        public BoardController(MindnoteContext context, MindnoteContextForView contextForView, UserService userService)
        {
            _context = context;
            _contextForView = contextForView;
        }

        [HttpGet]
        public ActionResult<List<view_board>> GetAll()
        {
            return _contextForView.view_board.Where(x => x.is_public == true && x.deleted_at == null).OrderByDescending(x => x.created_at).Take(20).ToList();
        }

        [HttpGet]
        [Route("sitemap/")]
        public ActionResult<List<dynamic>> GetAllForSiteMap()
        {
            return _contextForView.view_board.Where(x => x.is_public == true && x.deleted_at == null)
                .OrderByDescending(x => x.created_at)
                .Select(board => new
                {
                    latest_updated_at = board.latest_updated_at,
                    id = board.id
                })
                .ToList<dynamic>();
        }

        [HttpGet]
        [Route("{boardId}/")]
        public ActionResult<view_board> Get([FromRoute] Int32 boardId)
        {
            view_board result = _contextForView.view_board.FirstOrDefault(x =>
                x.id == boardId && x.deleted_at == null);
            if (result == null)
            {
                throw new MindnoteException("嗚喔！ 分類已經被刪除，無法瀏覽", HttpStatusCode.NotFound);
            }
            else if (!result.is_public)
            {
                throw new MindnoteException("這個分類被作者隱藏起來了～～", HttpStatusCode.Unauthorized);
            }
            else
            {
                return result;
            }
        }

        [HttpGet]
        [Route("{boardId}/nodes/")]
        public ActionResult<List<view_node>> GetNodes([FromRoute] Int32 boardId)
        {
            board board = _context.board.FirstOrDefault(x =>
                x.id == boardId && x.deleted_at == null);
            if (board == null)
            {
                throw new MindnoteException("嗚喔！ 分類已經被刪除，無法瀏覽", HttpStatusCode.NotFound);
            }
            else if (!board.is_public)
            {
                throw new MindnoteException("這個分類被作者隱藏起來了～～", HttpStatusCode.Unauthorized);
            }
            else
            {
                return _contextForView.view_node.Where(x => x.board_id == board.id && x.deleted_at == null).ToList();
            }
        }

        [HttpGet]
        [Route("{boardId}/relationship/")]
        public ActionResult<List<view_node_relationship>> GetRelationship([FromRoute] Int32 boardId)
        {
            board board = _context.board.FirstOrDefault(x =>
                x.id == boardId);
            if (board == null)
            {
                throw new MindnoteException("嗚喔！ 分類已經被刪除，無法瀏覽", HttpStatusCode.NotFound);
            }
            else if (!board.is_public)
            {
                throw new MindnoteException("這個分類被作者隱藏起來了～～", HttpStatusCode.Unauthorized);
            }
            else
            {
                return _contextForView.view_node_relationship.Where(x => x.board_id == board.id).ToList();
            }
        }

        [HttpGet]
        [Route("{boardId}/nodes/{nodeId}/")]
        public ActionResult<view_node> GetNode([FromRoute] Int32 boardId, [FromRoute] Int32 nodeId)
        {
            view_node result = _contextForView.view_node.FirstOrDefault(x =>
                x.id == nodeId && x.deleted_at == null && x.board_id == boardId);

            board board = _context.board.FirstOrDefault(x => x.id == boardId && x.deleted_at == null);
            if (board == null)
            {
                throw new MindnoteException("嗚喔！ 筆記的分類已經被刪除，無法瀏覽", HttpStatusCode.NotFound);
            }
            else if (!board.is_public)
            {
                throw new MindnoteException("這個分類被作者隱藏起來了～～", HttpStatusCode.Unauthorized);
            }
            else if (result == null)
            {
                throw new MindnoteException("嗚喔！ 筆記已經被刪除，無法瀏覽", HttpStatusCode.NotFound);
            }
            else
            {
                return result;
            }
        }

    }
}